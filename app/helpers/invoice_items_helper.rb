

module InvoiceItemsHelper

  def invoice_item_dynamic_cost_parameter_object(invoice_item)
    finalized_hash = {}
    invoice_item.dynamic_cost_parameter_definitions.each do |key, type|
      finalized_hash[key] = nil
      finalized_hash["#{key}_type"] = type
    end
    OpenStruct.new(finalized_hash.merge(invoice_item.dynamic_cost_parameters))
  end

end
