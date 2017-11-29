# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoicesController < CrudController
  self.nesting = Group
  self.sort_mappings = { recipient: Person.order_by_name_statement }
  self.search_columns = [:title, :sequence_number, 'people.last_name', 'people.email']
  self.permitted_attrs = [:title, :description, :state, :due_at,
                          :recipient_id, :recipient_email, :recipient_address,
                          invoice_items_attributes: [
                            :id,
                            :name,
                            :description,
                            :unit_cost,
                            :vat_rate,
                            :count,
                            :_destroy
                          ]]


  def destroy
    cancelled = run_callbacks(:destroy) { entry.update(state: :cancelled) }
    set_failure_notice unless cancelled
    respond_with(entry, success: cancelled, location: group_invoices_path(parent))
  end

  def show
    respond_to do |format|
      format.html { render_html }
      format.pdf { render_pdf }
    end
  end

  def index
    respond_to do |format|
      format.html { super }
      format.pdf { render_multiple_pdf }
    end
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

  def render_pdf
    pdf = Export::Pdf::Invoice.render(entry, pdf_options)
    filename = "#{entry.title.tr(' ', '_').downcase.scan(/[a-z0-9äöüéèêáàâ_]/i).join}.pdf"
    send_data pdf, type: :pdf, disposition: 'inline', filename: filename
  end

  def render_multiple_pdf
    pdf = Export::Pdf::Invoice.render_multiple(invoices.includes(:invoice_items), pdf_options)
    filename = "#{t('activerecord.models.invoice.other').downcase}.pdf"
    send_data pdf, type: :pdf, disposition: 'inline', filename: filename
  end

  def list_entries
    scope = super.includes(recipient: [:groups, :roles]).references(:recipient).list
    scope.page(params[:page]).per(50)
  end

  def authorize_class
    authorize!(:create, parent.invoices.build)
  end

  def reminder_attrs
    @reminder_attrs ||= flash[:payment_reminder]
  end

  def payment_attrs
    @payment_attrs ||= flash[:payment] || { amount: entry.total }
  end

  def pdf_options
    {
      articles: params[:articles] != 'false',
      esr: params[:esr] != 'false'
    }
  end

  def invoices
    return entries if invoice_ids.blank?
    Invoice.where(id: invoice_ids)
  end

  def invoice_ids
    params[:invoice_ids].to_s.split(',')
  end

end
