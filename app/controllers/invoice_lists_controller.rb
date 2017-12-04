# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceListsController < CrudController
  self.nesting = Group
  self.permitted_attrs = [:title,
                          :description,
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
    jobs = invoices.map do |invoice|
      alert('not_draft', invoice) && next unless invoice.state.draft?

      Invoice::SendNotificationJob.new(invoice, current_user).enqueue!
    end.compact

    redirect_with(count: jobs.count)
  end

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

  def list_entries
    super.includes(recipient: [:groups, :roles])
  end

  def invoices
    parent.invoices.where(id: params[:ids].to_s.split(','))
  end

  def redirect_with(attrs)
    message = I18n.t("#{controller_name}.#{action_name}", attrs)
    key = attrs[:count] > 0 ? :notice : :alert
    flash[key] << message
    redirect_to group_invoices_path(parent)
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
