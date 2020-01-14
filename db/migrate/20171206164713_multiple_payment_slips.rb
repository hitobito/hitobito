# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MultiplePaymentSlips < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :payment_slip, :string, null: false, default: 'ch_es'
    add_column :invoices, :beneficiary, :text

    add_column :invoice_configs, :payment_slip, :string, null: false, default: 'ch_es'
    add_column :invoice_configs, :beneficiary, :text
  end
end
