# == Schema Information
#
# Table name: invoice_items
#
#  id          :integer          not null, primary key
#  invoice_id  :integer          not null
#  name        :string           not null
#  description :text
#  vat_rate    :decimal(5, 2)
#  unit_cost   :decimal(12, 2)   not null
#  count       :integer          default(1), not null
#

class InvoiceItem < ActiveRecord::Base

  belongs_to :invoice

  validates_by_schema

  def to_s
    "#{name}: #{total} (#{amount} / #{vat})"
  end

  def total
    cost + vat
  end

  def cost
    unit_cost ? unit_cost * count : 0
  end

  def vat
    vat_rate ? cost * (vat_rate / 100) : 0
  end

end
