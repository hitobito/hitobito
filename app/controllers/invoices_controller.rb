# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoicesController < CrudController
  include Api::JsonPaging
  include RenderMessagesExports
  include AsyncDownload

  decorates :invoice

  self.nesting = Group
  self.optional_nesting = [InvoiceList]

  self.sort_mappings = { last_payment_at: Invoice.order_by_payment_statement,
                         amount_paid: Invoice.order_by_amount_paid_statement,
                         recipient: Person.order_by_name_statement,
                         sequence_number: Invoice.order_by_sequence_number_statement }
  self.remember_params += [:year, :state, :due_since, :invoice_list_id]

  self.search_columns = [:title, :sequence_number, 'people.last_name', 'people.first_name',
                         'people.email', 'people.company_name']
  self.permitted_attrs = [:title, :description, :state, :due_at, :issued_at,
                          :recipient_id, :recipient_email, :recipient_address,
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

  before_render_index :year_from

  helper_method :group, :invoice_list

  after_destroy :update_invoice_list_total

  def new
    recipient = model_params && Person.find(model_params[:recipient_id])
    if recipient && can?(:update, recipient)
      entry.recipient_id = recipient.id
      entry.send(:set_recipient_fields)
    end
    entry.attributes = { payment_information: entry.invoice_config.payment_information }
  end

  def index
    respond_to do |format|
      format.html { super }
      format.pdf  { generate_pdf(list_entries.includes(:invoice_items)) }
      format.csv  { render_invoices_csv(list_entries.includes(:invoice_items)) }
      format.json { render_entries_json(list_entries.includes(:invoice_items,
                                                              :payments,
                                                              :payment_reminders)) }
    end
  end

  def show
    @invoice_items = InvoiceItemDecorator.decorate_collection(entry.invoice_items)
    respond_to do |format|
      format.html { build_payment }
      format.pdf  { generate_pdf([entry]) }
      format.csv  { render_invoices_csv([entry]) }
      format.json { render_entry_json }
    end
  end

  def destroy
    cancelled = run_callbacks(:destroy) { entry.update(state: :cancelled) }
    set_failure_notice unless cancelled
    respond_with(entry, success: cancelled, location: group_invoices_path(group))
  end

  private

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
    letter = parent.message if parent.is_a?(InvoiceList)
    if letter
      render_pdf_in_background(letter)
    else
      format = :pdf
      with_async_download_cookie(format, filename(format, invoices)) do |filename|
        Export::InvoicesJob.new(format,
                                current_person.id,
                                invoices.pluck(:id),
                                pdf_options.merge({ filename: filename })).enqueue!
      end
    end
  end

  def filename(extension, invoices)
    if invoices.size > 1
      "#{t('activerecord.models.invoice.other').downcase}.#{extension}"
    else
      invoices.first.filename(extension)
    end
  end

  def render_labels(invoices)
    unless params[:label_format_id]
      return redirect_back(fallback_location: group_invoices_path(group))
    end

    recipients = Invoice.to_contactables(invoices)
    pdf = Export::Pdf::Labels.new(find_and_remember_label_format).generate(recipients)
    send_data pdf, type: :pdf, disposition: 'inline'
  rescue Prawn::Errors::CannotFit
    redirect_back(fallback_location: group_invoices_path(group), alert: t('people.pdf.cannot_fit'))
  end

  def list_entries
    scope = super.list
    scope = scope.includes(:recipient).references(:recipient)
    scope = scope.joins(Invoice.last_payments_information)
    scope = scope.standalone if parent.is_a?(Group)
    scope = scope.page(params[:page]).per(50) unless params[:ids]
    Invoice::Filter.new(params).apply(scope)
  end

  def payment_attrs
    @payment_attrs ||= flash[:payment] || { amount: entry.amount_open }
  end

  def pdf_options
    {
      articles: params[:articles] != 'false',
      payment_slip: params[:payment_slip] != 'false'
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
    authorize!(:index_invoices, group)
  end

  def group
    parent.is_a?(InvoiceList) ? parent.group : parent
  end

  def invoice_list
    parent if parent.is_a?(InvoiceList)
  end

  def update_invoice_list_total
    entry.invoice_list&.update_total
  end

  def year_from
    if invoice_list
      @year_from ||= invoice_list.created_at.year
    end
  end

end
