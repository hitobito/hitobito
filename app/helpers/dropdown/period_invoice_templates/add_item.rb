#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class PeriodInvoiceTemplates::AddItem < Base
    attr_reader :form

    def initialize(template)
      super(template, translate(:add_item), :plus)
      init_items
    end

    private

    def init_items
      Settings.groups.period_invoice_templates.item_classes.keys.map(&:to_s).each do |item_class|
        add_item(item_class.constantize.model_name.human, item_class.constantize)
      end
    end

    def add_item(label, item_class)
      item = Item.new(label, "javascript:void(0)",
        data: {
          action: "period-invoice-template-form#add",
          period_invoice_template_form_item_class_param: item_class
        })
      @items << item
      item
    end
  end
end
