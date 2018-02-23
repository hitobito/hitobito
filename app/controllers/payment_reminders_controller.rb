# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PaymentRemindersController < CrudController
  self.permitted_attrs = [:message, :due_at]

  skip_before_action :entry

  def create
    entry.attributes = permitted_params.merge(invoice: invoice)
    custom_authorize!

    if save_entry
      redirect_to(return_path, notice: success_message)
    else
      flash[:payment_reminder] = permitted_params.to_h
      redirect_to(return_path, alert: error_messages.presence || failure_message)
    end
  end

  private

  def save_entry
    return entry.save if entry.invoice
    return entry.multi_create(invoices) if invoices.present?
    false
  end

  def failure_message
    I18n.t("#{controller_name}.#{action_name}.failure")
  end

  def success_message
    options = { count: (entry.invoice ? 1 : invoices.size) }
    I18n.t("#{controller_name}.#{action_name}.success", options)
  end

  def return_path
    entry.invoice ? group_invoice_path(group, entry.invoice) : group_invoices_path(group)
  end

  def custom_authorize!
    return authorize!(:create, entry) if entry.invoice

    invoices.each do |invoice|
      authorize!(:create, invoice.payment_reminders.build)
    end
  end

  def invoices
    @invoices ||= Invoice.remindable.where(group: group, id: ids)
  end

  def invoice
    return @invoice if defined?(@invoice)
    @invoice ||= Invoice.find_by(id: params[:invoice_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def ids
    @ids ||= params[model_identifier].delete(:ids).to_s.split(',')
  end

end
