
# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: invoice_items
#
#  id          :integer          not null, primary key
#  invoice_id  :integer          not null
#  name        :string(255)      not null
#  description :text(65535)
#  vat_rate    :decimal(5, 2)
#  unit_cost   :decimal(12, 2)   not null
#  count       :integer          default(1), not null
#  cost_center :string(255)
#  account     :string(255)
#

class InvoiceItemSerializer < ApplicationSerializer

  schema do
    json_api_properties

    map_properties :name,
                   :description,
                   :vat_rate,
                   :unit_cost,
                   :count,
                   :cost_center,
                   :account
  end
end

