# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Blasmusikverband. This file is part of
#  hitobito_sjas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sbv.

class AddStiToInvoiceItems < ActiveRecord::Migration[6.1]
  def up
    add_column :invoice_items, :type, :string, null: false, default: 'InvoiceItem'
    add_column :invoice_items, :cost, :decimal, precision: 12, scale: 2, null: true
    add_column :invoice_items, :dynamic_cost_parameters, :text

    InvoiceItem.update_all(type: 'InvoiceItem')
    InvoiceItem.where(variable_donation: true).update_all(type: 'InvoiceItem::VariableDonation') if defined? InvoiceItem::VariableDonation

    remove_column :invoice_items, :variable_donation
  end

  def down
    add_column :invoice_items, :variable_donation, :boolean, default: false, null: false

    InvoiceItem.where(type: 'InvoiceItem::VariableDonation').update_all(variable_donation: true)

    remove_column :invoice_items, :type
    remove_column :invoice_items, :cost
    remove_column :invoice_items, :dynamic_cost_parameters
  end
end
