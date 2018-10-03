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
  respond_to :js, only: [:new]

  helper_method :cancel_url

  def new
    assign_attributes
    entry.attributes = { payment_information: entry.invoice_config.payment_information }

    session[:invoice_referer] = request.referer
  end

  def create
    if multi_create
      message = flash_message(count: entry.recipients.size, title: entry.title)
      redirect_to return_path, notice: message
      session.delete :invoice_referer
    else
      render :new
    end
  end

  def update
    batch_update = Invoice::BatchUpdate.new(invoices.includes(:recipient), sender)
    batch_result = batch_update.call
    redirect_to return_path, batch_result.to_options
  end

  # rubocop:disable Rails/SkipsModelValidations
  def destroy
    count = invoices.update_all(state: :cancelled, updated_at: Time.zone.now)
    key = count > 0 ? :notice : :alert
    redirect_to(group_invoices_path(parent), key => flash_message(count: count))
  end

  def show
    redirect_to group_invoices_path(parent)
  end

  def self.model_class
    Invoice
  end

  private

  def multi_create
    assign_attributes
    entry.recipient = parent.people.first
    entry.multi_create if entry.valid?
  end

  def permitted_params
    super.merge(creator_id: current_user.id)
  end

  def return_path
    if params[:singular]
      group_invoice_path(parent, invoices.first)
    else
      group_invoices_path(parent)
    end
  end

  def sender
    params[:mail] == 'true' && current_user
  end

  def list_entries
    super.includes(recipient: [:groups, :roles])
  end

  def invoices
    parent.invoices.where(id: params[:ids].to_s.split(','))
  end

  def flash_message(attrs)
    I18n.t("#{controller_name}.#{action_name}", attrs)
  end

  def authorize
    authorize!(:create, parent.invoices.build)
  end

  def cancel_url
    session[:invoice_referer] || group_invoices_path(parent)
  end

end
