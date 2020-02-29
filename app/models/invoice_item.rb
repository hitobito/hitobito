# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
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

class InvoiceItem < ActiveRecord::Base

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
