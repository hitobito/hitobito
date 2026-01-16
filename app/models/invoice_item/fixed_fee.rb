# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: invoice_items
#
#  id                      :integer          not null, primary key
#  account                 :string
#  cost                    :decimal(12, 2)
#  cost_center             :string
#  count                   :integer          default(1), not null
#  description             :text
#  dynamic_cost_parameters :text
#  name                    :string           not null
#  type                    :string           default("InvoiceItem"), not null
#  unit_cost               :decimal(12, 2)   not null
#  vat_rate                :decimal(5, 2)
#  invoice_id              :integer          not null
#
# Indexes
#
#  index_invoice_items_on_invoice_id  (invoice_id)
#
class InvoiceItem::FixedFee < InvoiceItem
  attr_readonly :name, :dynamic_cost_parameters

  def name
    I18n.t(read_attribute(:name), scope: "fixed_fees.#{dynamic_cost_parameters[:fixed_fees]}")
  end
end
