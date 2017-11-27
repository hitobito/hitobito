# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
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
                          ],
  ]

  skip_authorize_resource
  before_action :authorize
  respond_to :js, only: [:new]

  def new
    assign_attributes
  end

  def create
    assign_attributes
    entry.recipient = parent.people.first
    succeeded = entry.multi_create if entry.valid?

    if succeeded
      redirect_with(count: entry.recipients.size, title: entry.title)
    else
      render :new
    end
  end

  def update
    sent_at = Time.zone.today
    due_at = sent_at + parent.invoice_config.due_days.days

    count = invoices.update_all(state: :sent,
                                due_at: due_at,
                                sent_at: sent_at,
                                updated_at: sent_at)

    redirect_with(count: count)
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
    parent.invoices.where(id: params[:ids])
  end

  def redirect_with(attrs)
    message = I18n.t("#{controller_name}.#{action_name}", attrs)
    key = attrs[:count] > 0 ? :notice : :alert
    redirect_to group_invoices_path(parent), key => message
  end

  def authorize
    authorize!(:create, parent.invoices.build)
  end

end
