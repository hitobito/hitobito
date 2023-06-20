# frozen_string_literal: true

#  Copyright (c) 2023, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class LetterWithInvoiceNew < Base
    def initialize(template, label: nil,
                   path: template.path_args(Message::LetterWithInvoice),
                   disabled_msg: nil, icon: :plus)
      super(template, label, icon)
      @label = label
      @path = path
      @disabled_msg = disabled_msg
      init_items
    end

    def button_or_dropdown
      if InvoiceItem.all_types.one? || @disabled_msg.present?
        single_button
      else
        to_s
      end
    end

    private

    def label
      @label || I18n.t('crud.new.title', model: Message::LetterWithInvoice.model_name.human)
    end

    def single_button
      return template.action_button(label, @path, @icon, disabled: @disabled_msg) if @disabled_msg

      template.action_button(label,
                             path,
                             @icon)
    end

    def init_items
      add_item(translate(:invoice), path)
      additional_sub_links.each do |key|
        add_item(translate(key), path(invoice_item: key))
      end
    end

    def path(invoice_item: nil)
      if invoice_item.present?
        template.new_polymorphic_path(@path, message: { type: Message::LetterWithInvoice },
                                      invoice_items: [invoice_item])
      else
        template.new_polymorphic_path(@path, message: { type: Message::LetterWithInvoice })
      end
    end

    def additional_sub_links
      InvoiceItem.type_mappings.keys
    end
  end
end

