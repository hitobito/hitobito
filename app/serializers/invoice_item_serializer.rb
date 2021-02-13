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
#  account     :string(255)
#  cost_center :string(255)
#  count       :integer          default(1), not null
#  description :text(16777215)
#  name        :string(255)      not null
#  unit_cost   :decimal(12, 2)   not null
#  vat_rate    :decimal(5, 2)
#  invoice_id  :integer          not null
#
# Indexes
#
#  index_invoice_items_on_invoice_id  (invoice_id)
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
