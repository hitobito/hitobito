# frozen_string_literal: true

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

class InvoiceItem < ActiveRecord::Base
  # used to map declassified type string to class constant
  class_attribute :type_mappings

  self.type_mappings = {}

  # Used to mark as dynamically calculated.
  class_attribute :dynamic

  self.dynamic = false

  # Allows to define the parameters for dynamic cost calculation.
  # These will also be rendered as an input on the invoice_list form.
  # Example:
  # self.dynamic_cost_parameter_definitions = {
  #   defined_at: :date
  # }
  class_attribute :dynamic_cost_parameter_definitions
  self.dynamic_cost_parameter_definitions = {}

  after_destroy :recalculate_invoice!

  before_update :recalculate, if: :count_or_unit_cost_changed?
  after_update :recalculate_invoice!

  belongs_to :invoice

  scope :list, -> { order(:name) }

  validates :unit_cost, money: true, allow_nil: true
  validates :unit_cost, presence: true, unless: :dynamic
  validates :count, presence: true, unless: :dynamic

  serialize :dynamic_cost_parameters, Hash

  class << self
    def all_types
      [InvoiceItem] + type_mappings.values
    end

    def add_type_mapping(declassified_string, klass)
      type_mappings[declassified_string] = klass
    end
  end

  def to_s
    "#{name}: #{total} (#{amount} / #{vat})"
  end

  def total
    recalculate unless cost

    cost&.+ vat
  end

  def recalculate
    self.cost = if dynamic
                  dynamic_cost
                else
                  unit_cost && count ? unit_cost * count : 0
                end

    self
  end

  def recalculate_invoice!
    invoice.recalculate!
  end

  def recalculate!
    recalculate.save!

    recalculate_invoice!
  end

  def vat
    recalculate unless cost

    vat_rate ? cost&.*((vat_rate / 100)) : 0
  end

  def count_or_unit_cost_changed?
    count_changed? || unit_cost_changed?
  end
end
