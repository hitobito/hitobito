# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceListsController < CrudController
  self.nesting = Group
  self.permitted_attrs = [:title,
                          :description,
                          :payment_information,
                          :payment_purpose,
                          :recipient_ids,
                          invoice_items_attributes: [
                            :name,
                            :description,
                            :unit_cost,
                            :vat_rate,
                            :count,
                            :_destroy
                          ]]

  skip_authorize_resource
  before_action :authorize
  before_action :prepare_flash
  respond_to :js, only: [:new]

  helper_method :cancel_url

  def new
    assign_attributes
    entry.attributes = { payment_information: entry.invoice_config.payment_information }

    session[:invoice_referer] = request.referer
  end

  def create
    assign_attributes
    entry.recipient = parent.people.first
    succeeded = entry.multi_create if entry.valid?

    if succeeded
      redirect_with(count: entry.recipients.size, title: entry.title)
      session.delete :invoice_referer
    else
      render :new
    end
  end

  def update
    updated = invoices.includes(:recipient).map do |invoice|
      alert('not_draft', invoice) && next unless invoice.draft?
      alert('no_mail', invoice) && next if send_mail? && invoice.recipient_email.blank?

      update_and_send_mail(invoice)
    end.compact

    redirect_with(count: updated.count) do
      group_invoice_path(parent, invoices.first) if params[:singular]
    end
  end

  # rubocop:disable Rails/SkipsModelValidations
  def destroy
    count = invoices.update_all(state: :cancelled, updated_at: Time.zone.now)
    redirect_with(count: count)
  end

  def show
    redirect_to group_invoices_path(parent)
  end

  def self.model_class
    Invoice
  end

  private

  def send_mail?
    params[:mail] == 'true'
  end

  def update_and_send_mail(invoice)
    invoice.update(state: send_mail? ? :sent : :issued).tap do
      enqueue_sender_job(invoice) if send_mail?
    end
  end

  def enqueue_sender_job(invoice)
    Invoice::SendNotificationJob.new(invoice, current_person).enqueue!
  end

  def list_entries
    super.includes(recipient: [:groups, :roles])
  end

  def invoices
    parent.invoices.where(id: params[:ids].to_s.split(','))
  end

  def redirect_with(attrs)
    i18n_prefix = "#{controller_name}.#{action_name}"
    message = I18n.t(i18n_prefix, attrs)
    key = attrs[:count] > 0 ? :notice : :alert
    flash[key] << message
    flash[key] << I18n.t("#{i18n_prefix}.background_send", attrs) if send_mail?
    path = yield if block_given?
    path ||= group_invoices_path(parent)
    redirect_to path
  end

  def prepare_flash
    flash[:notice] = []
    flash[:alert] = []
  end

  def alert(key, invoice)
    flash[:alert] << I18n.t(
      "#{controller_name}.#{action_name}.error.#{key}",
      number: invoice.sequence_number,
      name:   invoice.recipient_name
    )
  end

  def authorize
    authorize!(:create, parent.invoices.build)
  end

  def cancel_url
    session[:invoice_referer] || group_invoices_path(parent)
  end

end
