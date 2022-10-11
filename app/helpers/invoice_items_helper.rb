# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Blasmusikverband. This file is part of
#  hitobito_sjas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sbv.

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
