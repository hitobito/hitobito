#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
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

class InvoiceItem < ApplicationRecord
  after_destroy :recalculate!

  belongs_to :invoice

  scope :list, -> { order(:name) }

  validates :unit_cost, money: true, allow_nil: true
  delegate :recalculate!, to: :invoice

  validates_by_schema

  def to_s
    "#{name}: #{total} (#{amount} / #{vat})"
  end

  def total
    cost + vat
  end

  def cost
    unit_cost && count ? unit_cost * count : 0
  end

  def vat
    vat_rate ? cost * (vat_rate / 100) : 0
  end
end
