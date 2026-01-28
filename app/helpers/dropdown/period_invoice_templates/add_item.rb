#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class PeriodInvoiceTemplates::AddItem < Base
    attr_reader :form

    AVAILABLE_ITEMS = [ # rubocop:disable Style/MutableConstant meant to be extended in wagons
      PeriodInvoiceTemplate::RoleCountItem
    ]

    def initialize(template, form, *args)
      super(template, translate(:add_item), :plus)
      @form = form
      @options = args.extract_options!
      init_items
    end

    def to_s
      template.content_tag(:div, id: id, class: "btn-group dropdown #{@options[:class]}") do
        render_dropdown_button + render_items
      end
    end

    private

    def init_items
      AVAILABLE_ITEMS.each do |item_class|
        add_item(translate(item_class.name.demodulize.underscore), item_class)
      end
    end

    def add_item(label, item_class)
      item = LinkToAddItem.new(label, "javascript:void(0)", item_class:, form:)
      @items << item
      item
    end

    class LinkToAddItem < Item
      attr_accessor :item_class, :form

      def initialize(label, url, disabled_msg: nil, **options)
        @item_class = options.delete(:item_class)
        @form = options.delete(:form)
        super
      end

      def render(template)
        template.content_tag(:li, class: css_class) do
          template.safe_join([
            form.link_to_add(label, :items,
              class: "dropdown-item text w-100 align-with-form",
              model_object: item_class.new),
            render_sub_items(template)
          ].compact)
        end
      end
    end
  end
end
