# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PaymentsController < CrudController
  include FormatHelper
  include ActionView::Helpers::NumberHelper

  self.nesting = [Group, Invoice]
  self.permitted_attrs = [:amount, :received_at]

  def create
    assign_attributes

    if entry.save
      redirect_to(group_invoice_path(*parents), notice: flash_message)
    else
      flash[:payment] = permitted_params.to_h
      redirect_to(group_invoice_path(*parents))
    end
  end

  def flash_message
    I18n.t("#{controller_name}.#{action_name}.flash.success", amount: f(entry.amount))
  end

end
