# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceConfigsController < CrudController

  self.nesting = Group
  self.permitted_attrs = [:payment_information, :address, :iban, :account_number,
                          :payment_slip, :beneficiary, :payee, :participant_number,
                          :participant_number_internal, :email, 
                          payment_reminder_configs_attributes: [
                            :id, :title, :text, :level, :due_days
                          ]]

  before_render_form :build_payment_reminder_configs

  private

  def build_entry
    parent.invoice_config
  end

  def find_entry
    parent.invoice_config
  end

  def path_args(_)
    [parent, :invoice_config]
  end

  def build_payment_reminder_configs
    missing_payment_reminder_levels.each do |level|
      entry.payment_reminder_configs.build(level: level)
    end
  end

  def missing_payment_reminder_levels
    1.upto(3).to_a - entry.payment_reminder_configs.collect(&:level)
  end


end
