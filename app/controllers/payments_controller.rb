# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PaymentsController < CrudController
  include FormatHelper
  include AsyncDownload
  include ActionView::Helpers::NumberHelper

  self.nesting = [Group, Invoice]
  self.permitted_attrs = [:amount, :received_at]

  def index
    respond_to do |format|
      format.csv { render_tabular_entries_in_background(:csv) }
    end
  end

  def create
    assign_attributes

    Payment.transaction do
      if entry.save
        parent.invoice_list&.update_paid
        redirect_to(group_invoice_path(*parents), notice: flash_message)
      else
        flash[:payment] = permitted_params.to_h
        redirect_to(group_invoice_path(*parents))
      end
    end
  end

  private

  def render_tabular_entries_in_background(format)
    return_path = group_invoices_path(params[:group_id])
    with_async_download_cookie(format, :payment_export,
                               redirection_target: return_path) do |filename|
      render_tabular_in_background(format, filename)
    end
  end

  def render_tabular_in_background(format, filename)
    Export::PaymentsExportJob.new(
      format, current_person.id, entries.map(&:id),
      { filename: filename }
    ).enqueue!
  end

  def flash_message
    I18n.t("#{controller_name}.#{action_name}.flash.success", amount: f(entry.amount))
  end

  def assign_attributes
    super
    entry.status = :manually_created
  end

  def list_entries
    scope = super

    scope = scope.unassigned if params[:state] == 'without_invoice'
    scope = scope.where(received_at: from_param..to_param)

    scope
  end

  def from_param
    @from_param ||= extract_date_param(:from) || Date.today.beginning_of_year
  end

  def to_param
    @to_param ||= extract_date_param(:to) || Date.today.end_of_year
  end

  def extract_date_param(param)
    Date.parse(params[param])
  rescue TypeError, Date::Error
    nil
  end

  def model_scope
    if action_name == 'index'
      Payment
    else
      super
    end
  end
end
