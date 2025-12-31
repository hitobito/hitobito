#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceRunsController < CrudController
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
      :hide_total,
      :issued_at,
      invoice_items_attributes: [
        :name,
        :description,
        :cost_center,
        :account,
        :unit_cost,
        :vat_rate,
        :count,
        :type,
        :_destroy
      ]
    ]
  ]

  respond_to :js, only: [:new]

  helper_method :cancel_url, :fixed_fees?

  def new
    assign_attributes

    entry.invoice.payment_information = entry.invoice_config.payment_information
    session[:invoice_referer] = request.referer
  end

  def create # rubocop:todo Metrics/AbcSize
    assign_attributes
    entry.title = entry.invoice.title

    if entry.valid? && entry.save
      Invoice::BatchCreate.call(entry, LIMIT_CREATE)
      message = flash_message_create(count: entry.recipient_ids_count, title: entry.title)
      params[:invoice_run_id] = entry.id  # NOTE: make return_path behave as expected
      redirect_to return_path, notice: message
      session.delete :invoice_referer
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize!(:update, entry)

    batch_update = Invoice::BatchUpdate.new(invoices.includes(:recipient), sender)
    batch_result = batch_update.call
    redirect_to return_path, batch_result.to_options
  end

  # rubocop:disable Rails/SkipsModelValidations
  # NOTE: quite suprisingly, this destroy cancels invoices within the run.
  # The destroy of the run itself is handled by invoice_runs/destroy controller
  def destroy
    count = InvoiceRun.transaction do
      cancel_all_invoices.tap do
        entry.update_total
      end
    end
    params[:invoice_run_id] = entry.id  # NOTE: make return_path behave as expected
    key = (count > 0) ? :notice : :alert
    redirect_to(return_path, key => flash_message(count: count))
  end

  def show
    redirect_to group_invoices_path(parent)
  end

  def fixed_fees?(fees = nil)
    fees ? params[:fixed_fees] == fees.to_s : params.key?(:fixed_fees)
  end

  private

  def entry
    model_ivar_get || model_ivar_set(params[:invoice_run_id] ? find_entry : build_entry)
  end

  def find_entry
    parent.invoice_runs.find(params[:invoice_run_id])
  end

  def list_entries
    super.includes(:receiver).list.where(created_at: year_filter)
  end

  def return_path # rubocop:todo Metrics/AbcSize
    invoice_run_id = params[:invoice_run_id].presence
    if params[:singular]
      if invoice_run_id
        group_invoice_run_invoice_path(parent, invoice_run_id: invoice_run_id,
          id: invoices.first.id)
      else
        group_invoice_path(parent, invoices.first)
      end
    elsif params.dig(:invoice_run, :receiver_id)
      group_invoice_runs_path(parent)
    elsif invoice_run_id
      group_invoice_run_invoices_path(parent, invoice_run_id: invoice_run_id, returning: true)
    else
      group_invoices_path(parent, returning: true)
    end
  end

  def sender
    params[:mail] == "true" && current_user
  end

  def invoices
    parent.issued_invoices.where(id: list_param(:ids))
  end

  def flash_message(action: action_name, count: nil, title: nil)
    I18n.t("#{controller_name}.#{action}", count: count, title: title)
  end

  def flash_message_create(count:, title:)
    action_name = (count < LIMIT_CREATE) ? :create : :create_batch
    flash_message(action: action_name, count: count, title: title)
  end

  def cancel_url
    return group_path(parent) if fixed_fees?
    session[:invoice_referer] || group_invoices_path(parent)
  end

  # rubocop:todo Metrics/CyclomaticComplexity
  # rubocop:todo Metrics/MethodLength
  def assign_attributes # rubocop:disable Metrics/AbcSize # rubocop:todo Metrics/MethodLength
    if params[:ids].present?
      entry.recipient_ids = params[:ids]
    elsif params[:filter].present?
      entry.recipient_ids = recipient_ids_from_people_filter
    elsif model_params
      entry.attributes = permitted_params.slice(:receiver_id, :receiver_type, :recipient_ids)
    end
    entry.creator = current_user
    entry.invoice = parent.issued_invoices
      .build(model_params.present? ? permitted_params[:invoice] : {})

    if params[:invoice_items].present?
      entry.invoice.invoice_items = params[:invoice_items].map do |type|
        item = InvoiceItem.type_mappings[type.to_sym].new
        item.name = item.model_name.human
        item
      end
    end

    if fixed_fees?
      InvoiceRuns::FixedFee.for(params[:fixed_fees]).prepare(entry) do |key, text|
        flash.now[key] = text
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity

  def recipient_ids_from_people_filter
    group = Group.find(params.dig(:filter, :group_id))
    filter_params = params[:filter].to_unsafe_h.transform_values(&:presence)
    filter = Person::Filter::List.new(group, current_user, filter_params)
    filter.entries.unscope(:order).pluck(:id)
  end

  def authorize_class
    authorize!(:index_issued_invoices, parent)
  end

  def permitted_params
    # Used to permit dynamic_cost_parameters for invoice items that define them
    @permitted_params ||= super.tap do |permitted|
      next unless permitted.dig(:invoice, :invoice_items_attributes)

      permitted.dig(:invoice, :invoice_items_attributes).each do |index, attrs|
        parameters = params.dig(:invoice_run, :invoice, :invoice_items_attributes,
          index, :dynamic_cost_parameters)
        attrs[:dynamic_cost_parameters] = parameters&.to_unsafe_hash || {}
      end
    end
  end

  def cancel_all_invoices
    invoices.update_all(state: :cancelled, updated_at: Time.zone.now)
  end
end
