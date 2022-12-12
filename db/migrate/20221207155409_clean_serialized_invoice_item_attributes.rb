# frozen_string_literal: true

# Copyright (c) 2022, hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

class CleanSerializedInvoiceItemAttributes < ActiveRecord::Migration[6.1]
  def up
    # m.invoice_attributes # return this hash:
    # {"invoice_items_attributes"=>
    #   {"0"=>
    #     {"name"=>"ein Name",
    #      "description"=> "eine Beschreibung",
    #      "unit_cost"=>"50.0",
    #      "vat_rate"=>"",
    #      "count"=>"1",
    #      "cost_center"=>"",
    #      "account"=>"3000",
    #      "variable_donation"=>"false",
    #      "_destroy"=>"false"}}}
    transform_invoice_attributes do |attributes|
      migrate_variable_donation_attribute_to_type(attributes)
    end
  end

  def down
    transform_invoice_attributes do |attributes|
      migrate_variable_donation_type_to_attribute(attributes)
    end
  end

  def transform_invoice_attributes
    Message::LetterWithInvoice.where.not(invoice_attributes: nil).find_each do |message|
      message.invoice_attributes = message.invoice_attributes.map do |relation_type, list|
        [
          relation_type,
          list.map do |index, attributes_hash|
            [
              index,
              yield(attributes_hash)
            ]
          end.to_h
        ]
      end.to_h
      message.save(validate: false)
    end
  end

  def migrate_variable_donation_attribute_to_type(hash)
    type = if defined?(InvoiceItem::VariableDonation) &&
                hash.fetch('variable_donation', 'false').to_s == 'true'
               'InvoiceItem::VariableDonation'
             else
               'InvoiceItem'
             end

    hash.except('variable_donation').merge({ 'type' => type })
  end

  def migrate_variable_donation_type_to_attribute(hash)
    variable_donation = hash.fetch('type', 'InvoiceItem').to_s == 'InvoiceItem::VariableDonation'

    hash.except('type').merge({ 'variable_donation' => variable_donation })
  end
end
