class CleanSerializedInvoiceItemAttributes < ActiveRecord::Migration[6.1]
  def change
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
    Message::LetterWithInvoice.where.not(invoice_attributes: nil).find_each do |message|
      message.invoice_attributes = message.invoice_attributes.map do |relation_type, list|
        [
          relation_type,
          list.map do |index, attributes_hash|
            [
              index,
              migrate_variable_donation_attribute_to_type(attributes_hash)
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

    hash.except('variable_donation').merge(type: type)
  end
end
