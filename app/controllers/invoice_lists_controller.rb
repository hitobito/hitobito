#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceListsController < CrudController
  include YearBasedPaging

  LIMIT_CREATE = 100

  self.nesting = Group
  self.permitted_attrs = [
    :receiver_id,
    :receiver_type,
    :recipient_ids,
    invoice: [
      :title,
      :description,
      :payment_information,
      :payment_purpose,
      invoice_items_attributes: [
        :name,
        :description,
        :unit_cost,
        :vat_rate,
        :count,
        :_destroy,
      ],
    ],
  ]

  skip_authorize_resource
  before_action :authorize
  respond_to :js, only: [:new]

  helper_method :cancel_url

  def new
    assign_attributes

    session[:invoice_referer] = request.referer
  end

  def create
    assign_attributes
    entry.title = entry.invoice.title

    if entry.valid?
      result = Invoice::BatchCreate.call(entry, LIMIT_CREATE)
      message = flash_message_create(count: entry.recipient_ids_count, title: entry.title)
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
    redirect_to(group_invoices_path(parent, returning: true), key => flash_message(count: count))
  end

  def show
    redirect_to group_invoices_path(parent)
  end

  private

  def list_entries
    super.includes(:receiver).list.where(created_at: Date.new(year, 1, 1).all_year)
  end

  def return_path
    invoice_list_id = params[:invoice_list_id].presence
    if params[:singular]
      group_invoice_path(parent, invoices.first)
    elsif params.dig(:invoice_list, :receiver_id)
      group_invoice_lists_path(parent)
    elsif invoice_list_id
      group_invoice_list_invoices_path(parent, invoice_list_id: invoice_list_id, returning: true)
    else
      group_invoices_path(parent, returning: true)
    end
  end

  def sender
    params[:mail] == "true" && current_user
  end

  def invoices
    parent.invoices.where(id: list_param(:ids))
  end

  def flash_message(action: action_name, count: nil, title: nil)
    I18n.t("#{controller_name}.#{action}", count: count, title: title)
  end

  def flash_message_create(count:, title:)
    action_name = count < LIMIT_CREATE ? :create : :create_batch
    flash_message(action: action_name, count: count, title: title)
  end

  def authorize
    authorize!(:create, parent.invoices.build)
  end

  def cancel_url
    session[:invoice_referer] || group_invoices_path(parent)
  end

  def assign_attributes # rubocop:disable Metrics/AbcSize
    if params[:ids].present?
      entry.recipient_ids = params[:ids]
    elsif params[:filter].present?
      entry.recipient_ids = recipient_ids_from_people_filter
    else
      entry.attributes = permitted_params.slice(:receiver_id, :receiver_type, :recipient_ids)
    end
    entry.creator = current_user
    entry.invoice = parent.invoices.build(permitted_params[:invoice])
  end

  def recipient_ids_from_people_filter
    group = Group.find(params.dig(:filter, :group_id))
    filter_params = params[:filter].to_unsafe_h.transform_values(&:presence)
    filter = Person::Filter::List.new(group, current_user, filter_params)
    filter.entries.pluck(:id).join(",")
  end

  def authorize_class
    authorize!(:index_invoices, parent)
  end
end
