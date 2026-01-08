#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoicesController < CrudController
  include Api::JsonPaging
  include RenderMessagesExports
  include AsyncDownload

  decorates :invoice

  self.nesting = Group
  self.optional_nesting = [InvoiceRun]

  self.sort_mappings = {
    last_payment_at: Invoice.order_by_payment_statement,
    amount_paid: Invoice.order_by_amount_paid_statement,
    recipient: Person.order_by_name_statement,
    sequence_number: Invoice.order_by_sequence_number_statement
  }

  self.remember_params += [:year, :state, :due_since, :invoice_run_id]

  self.search_columns = [:title, :sequence_number, "groups.name", "groups.email",
    "people.last_name", "people.first_name", "people.email", "people.company_name"]
  self.permitted_attrs = [:title, :description, :state, :due_at, :issued_at,
    :recipient_type, :recipient_id, :recipient_email, :recipient_company_name, :recipient_name,
    :recipient_address_care_of, :recipient_street, :recipient_housenumber, :recipient_postbox,
    :recipient_town, :recipient_zip_code, :recipient_country,
    :payment_information, :payment_purpose, :hide_total,
    invoice_items_attributes: [
      :id,
      :name,
      :description,
      :unit_cost,
      :vat_rate,
      :count,
      :cost_center,
      :account,
      :_destroy
    ]]

  helper_method :group, :invoice_run, :filter_params

  after_destroy :update_invoice_run_total

  def index
    respond_to do |format|
      format.html { super }
      format.pdf { generate_pdf(list_entries.includes(:invoice_items)) }
      format.csv { render_invoices_csv(list_entries.includes(:invoice_items)) }
      format.json {
        render_entries_json(
          list_entries.includes(:invoice_items, :payments, :payment_reminders)
        )
      }
    end
  end

  def show
    @invoice_items = InvoiceItemDecorator.decorate_collection(entry.invoice_items)
    respond_to do |format|
      format.html { build_payment }
      format.pdf { generate_pdf([entry]) }
      format.csv { render_invoices_csv([entry]) }
      format.json { render_entry_json }
    end
  end

  def new
    recipient = find_recipient
    if recipient && can?(:update, recipient)
      entry.recipient = recipient
      entry.send(:set_recipient_fields)
    end
    entry.attributes = {payment_information: entry.invoice_config.payment_information}
  end

  def destroy
    cancelled = run_callbacks(:destroy) { entry.update(state: :cancelled) }
    set_failure_notice unless cancelled
    respond_with(entry, success: cancelled, location: invoices_return_path)
  end

  private

  def invoices_return_path
    if invoice_run
      group_invoice_run_invoices_path(group, invoice_run, returning: true)
    else
      group_invoices_path(group, returning: true)
    end
  end

  def render_entries_json(entries)
    paged_entries = entries.page(params[:page])
    render json: [paging_properties(paged_entries),
      ListSerializer.new(paged_entries,
        group: group,
        page: params[:page],
        serializer: InvoiceSerializer,
        controller: self)].inject(&:merge)
  end

  def render_entry_json
    render json: InvoiceSerializer.new(entry, group: group, controller: self)
  end

  def build_payment
    @payment = entry.payments.build(payment_attrs)
    @payment_valid = payment_attrs ? @payment.valid? : true
  end

  def permitted_params
    super.merge(creator_id: current_user.id)
  end

  def recipient_type_param = model_params.try(:[], :recipient_type).presence

  def recipient_id_param = model_params.try(:[], :recipient_id).presence

  def find_recipient
    return unless recipient_type_param && recipient_id_param

    recipient_type_param.safe_constantize.find_by(id: recipient_id_param)
  end

  def generate_pdf(invoices)
    if params[:label_format_id]
      render_labels(invoices)
    else
      render_invoices_pdf(invoices)
    end
  end

  def render_invoices_csv(invoices)
    csv = Export::Tabular::Invoices::List.csv(invoices)
    send_data csv, type: :csv, filename: filename(:csv, invoices)
  end

  def render_invoices_pdf(invoices)
    letter = parent.message if parent.is_a?(InvoiceRun)
    if letter
      render_pdf_in_background(letter)
    else
      format = :pdf
      with_async_download_cookie(format, filename(format, invoices)) do |filename|
        Export::InvoicesJob.new(format,
          current_person.id,
          invoices.map(&:id), # pluck would replace the whole select, removing a DISTINCT as well
          pdf_options.merge({filename: filename})).enqueue!
      end
    end
  end

  def filename(extension, invoices)
    if invoices.size > 1
      "#{t("activerecord.models.invoice.other").downcase}.#{extension}"
    else
      invoices.first.filename(extension)
    end
  end

  def render_labels(invoices)
    unless params[:label_format_id]
      return redirect_back(fallback_location: group_invoices_path(group))
    end

    recipients = invoices.map(&:recipient).compact
    pdf = Export::Pdf::Labels.new(find_and_remember_label_format).generate(recipients)
    send_data pdf, type: :pdf, disposition: "inline"
  rescue Prawn::Errors::CannotFit
    redirect_back(fallback_location: group_invoices_path(group), alert: t("people.pdf.cannot_fit"))
  end

  def parent_scope
    parent.is_a?(InvoiceRun) ? parent.invoices : parent.issued_invoices
  end

  def list_entries
    # scope = super.list.with_aggregated_payments # NOTE: removing this scope resolves problems with scope.count in MultiselectHelper#extended_all_checkbox
    scope = super.list
    scope = scope.joins(
      <<~SQL
        LEFT JOIN people ON people.id = invoices.recipient_id AND invoices.recipient_type = 'Person'
        LEFT JOIN groups ON groups.id = invoices.recipient_id AND invoices.recipient_type = 'Group'
      SQL
    )
    scope = scope.standalone unless parents.any?(InvoiceRun)
    scope = scope.page(params[:page]) unless params[:ids]
    Invoice::Filter.new(params.merge(filter_params)).apply(scope).with_recipients
  end

  def payment_attrs
    @payment_attrs ||= flash[:payment] || {amount: entry.amount_open}
  end

  def pdf_options
    {
      articles: params[:articles] != "false",
      payment_slip: params[:payment_slip] != "false",
      reminders: params[:reminders] != "false"
    }
  end

  def find_and_remember_label_format
    LabelFormat.find(params[:label_format_id]).tap do |label_format|
      unless current_user.last_label_format_id == label_format.id
        current_user.update_column(:last_label_format_id, label_format.id)
      end
    end
  end

  def authorize_class
    authorize!(:index_issued_invoices, group)
  end

  def group
    parent.is_a?(InvoiceRun) ? parent.group : parent
  end

  def invoice_run
    parent if parent.is_a?(InvoiceRun)
  end

  def update_invoice_run_total
    entry.invoice_run&.update_total
  end

  def filter_params
    year = invoice_run&.created_at&.year || Time.zone.today.year
    {from: params[:from] || "1.1.#{year}", to: params[:to] || "31.12.#{year}"}
  end
end
