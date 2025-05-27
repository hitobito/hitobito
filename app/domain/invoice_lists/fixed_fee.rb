# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceLists::FixedFee
  attr_reader :fee, :config, :layer_group_ids

  def self.for(fee, layer_group_ids = nil)
    new(fee, layer_group_ids)
  end

  def initialize(fee, layer_group_ids = nil)
    @fee = fee
    @layer_group_ids = layer_group_ids
    @config = Settings.invoice_lists.fixed_fees.send(fee)
    fail "No config exists for #{fee}" unless config
  end

  def prepare(invoice_list)
    invoice_list.receivers = receivers.build
    invoice_list.invoice.invoice_items = invoice_items

    if block_given? && receivers.layers_with_missing_receiver.any?
      yield [:warning, missing_receivers_message]
    end
  end

  def receivers
    @receivers ||= InvoiceLists::Receivers.new(config.receivers, layer_group_ids)
  end

  def items
    @items ||= config.items.map(&:to_h).map do |attrs|
      item_class_for(attrs).new(**attrs.merge(fee:, layer_group_ids: receivers.addressable_layer_group_ids))
    end
  end

  def invoice_items
    items.map(&:to_invoice_item)
  end

  private

  def missing_receivers_message
    t(".recipient_role_group_mismatch", groups: receivers.layers_with_missing_receiver.map(&:name).join(", "))
  end

  def t(key, options = {})
    I18n.t(key, **options.merge(scope: "invoice_lists/fixed_fee"))
  end

  def item_class_for(attrs)
    InvoiceLists::RoleItem
  end
end
