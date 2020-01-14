# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ModifyInvoice < ActiveRecord::Migration[4.2]
  def change
    add_column :invoice_configs, :iban, :string
    remove_column :invoice_configs, :page_size, :integer

    add_column :invoices, :iban, :string
    add_column :invoices, :payment_purpose, :text
    add_column :invoices, :payment_information, :text
  end
end
