# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoicesController < CrudController
  decorates :invoice

  self.nesting = Group
  self.sort_mappings = { recipient: Person.order_by_name_statement }
  self.search_columns = [:title, :sequence_number, 'people.last_name', 'people.email']
  self.permitted_attrs = [:title, :description, :state, :due_at,
                          :recipient_id, :recipient_email, :recipient_address,
                          :payment_information, :payment_purpose,
                          invoice_items_attributes: [
                            :id,
                            :name,
                            :description,
                            :unit_cost,
                            :vat_rate,
                            :count,
                            :_destroy
                          ]]

  def new
    assign_attributes
    entry.attributes = { payment_information: entry.invoice_config.payment_information }
  end

  def index
    respond_to do |format|
      format.html { super }
      format.pdf { generate_pdf(list_entries.includes(:invoice_items)) }
      format.csv { render_invoices_csv(list_entries.includes(:invoice_items)) }
    end
  end

  def show
    @invoice_items = InvoiceItemDecorator.decorate_collection(entry.invoice_items)
    respond_to do |format|
      format.html { render_html }
      format.pdf { generate_pdf([entry]) }
      format.csv { render_invoices_csv([entry]) }
    end
  end

  def destroy
    cancelled = run_callbacks(:destroy) { entry.update(state: :cancelled) }
    set_failure_notice unless cancelled
    respond_with(entry, success: cancelled, location: group_invoices_path(parent))
  end

  private

  def render_html
    if entry.remindable?
      @reminder = entry.payment_reminders.build(reminder_attrs)
      @reminder_valid = reminder_attrs ? @reminder.valid? : true

      @payment = entry.payments.build(payment_attrs)
      @payment_valid = payment_attrs ? @payment.valid? : true
    end
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
    pdf = Export::Pdf::Invoice.render_multiple(invoices, pdf_options)
    send_data pdf, type: :pdf, disposition: 'inline', filename: filename(:pdf, invoices)
  end

  def filename(extension, invoices)
    if invoices.size > 1
      "#{t('activerecord.models.invoice.other').downcase}.#{extension}"
    else
      invoices.first.filename(extension)
    end
  end

  def render_labels(invoices)
    recipients = Invoice.to_contactables(invoices)
    pdf = Export::Pdf::Labels.new(find_and_remember_label_format).generate(recipients)
    send_data pdf, type: :pdf, disposition: 'inline'
  rescue Prawn::Errors::CannotFit
    redirect_to :back, alert: t('people.pdf.cannot_fit')
  end

  def list_entries
    scope = super.includes(recipient: [:groups, :roles]).references(:recipient).list
    scope = scope.page(params[:page]).per(50)
    Invoice::Filter.new(params).apply(scope)
  end

  def reminder_attrs
    @reminder_attrs ||= flash[:payment_reminder]
  end

  def payment_attrs
    @payment_attrs ||= flash[:payment] || { amount: entry.amount_open }
  end

  def pdf_options
    {
      articles: params[:articles] != 'false',
      esr: params[:esr] != 'false'
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
    authorize!(:index_invoices, parent)
  end

end
