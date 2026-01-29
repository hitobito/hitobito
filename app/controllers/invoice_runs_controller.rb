#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceRunsController < CrudController
  include YearBasedPaging

  LIMIT_CREATE = 100

  self.remember_params = [:year]

  self.nesting = Group
  self.permitted_attrs = [
    :recipient_source_id,
    :recipient_source_type,
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
      Invoice::BatchCreate.call(entry, current_user, LIMIT_CREATE)
      message = flash_message_create(count: entry.recipients(current_user).count,
        title: entry.title)
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

  def fixed_fees?
    params.key?(:fixed_fees)
  end

  private

  def entry
    model_ivar_get || model_ivar_set(params[:invoice_run_id] ? find_entry : build_entry)
  end

  def find_entry
    parent.invoice_runs.find(params[:invoice_run_id])
  end

  def list_entries
    super.includes(:recipient_source).list.where(created_at: year_filter)
  end

  def return_path # rubocop:todo Metrics/AbcSize,Metrics/MethodLength
    invoice_run_id = params[:invoice_run_id].presence
    if params[:singular]
      if invoice_run_id
        group_invoice_run_invoice_path(
          parent, invoice_run_id: invoice_run_id, id: invoices.first.id
        )
      else
        group_invoice_path(parent, invoices.first)
      end
    elsif params.dig(:invoice_run, :recipient_source_id)
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
    Invoice::Filter.new(params).apply_or_none(parent.issued_invoices)
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
    entry.creator = current_user
    entry.invoice = parent.issued_invoices
      .build(model_params.present? ? permitted_params[:invoice] : {})
    entry.recipient_source = InvoiceRuns::RecipientSourceBuilder.new(params,
      @group).recipient_source

    # TODO in #3752, move this logic out of here into the period_invoice_templates
    # if fixed_fees?
    #   InvoiceRuns::FixedFee.for(params[:fixed_fees]).prepare(entry) do |key, text|
    #     flash.now[key] = text
    #   end

    if params[:invoice_items].present?
      entry.invoice.invoice_items = params[:invoice_items].map do |type|
        item = InvoiceItem.type_mappings[type.to_sym].new
        item.name = item.model_name.human
        item
      end
    end

    # TODO in #3752, move this logic out of here into the period_invoice_templates
    # if fixed_fees?
    #   InvoiceRuns::FixedFee.for(params[:fixed_fees]).prepare(entry) do |key, text|
    #     flash.now[key] = text
    #   end
    # end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity

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
