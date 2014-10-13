# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class Base
    include Translatable

    attr_accessor :template, :label, :main_link, :icon, :button_class
    attr_reader :items

    delegate :content_tag, :link_to, :safe_join, to: :template

    def initialize(template, label, icon = nil)
      @template = template
      @label = label
      @icon = icon
      @main_link = nil
      @button_class = 'btn'
      @items = []
    end

    def to_s
      template.button_group do
        render_dropdown_button +
        render_items
      end
    end

    def add_divider
      @items << Divider.new
    end

    def add_item(label, url, options = {})
      item = Item.new(label, url, options)
      @items << item
      item
    end

    private

    def render_dropdown_button
      safe_join([
        label_with_link,
        content_tag(:a,
                    class: "dropdown-toggle #{button_class}",
                    href: '#',
                    data: { toggle: 'dropdown' }) do
          safe_join([label_without_link,
                     content_tag(:b, '', class: 'caret')].compact, ' ')
        end
      ].compact, ' ')
    end

    def label_with_link
      if main_link
        template.action_button(label, main_link, icon, in_button_group: true)
      end
    end

    def label_without_link
      unless main_link
        if icon
          safe_join([template.icon(icon), label], ' ')
        else
          label
        end
      end
    end

    def render_items
      template.content_tag_nested(:ul, items, class: 'dropdown-menu', role: 'menu') do |item|
        item.render(template)
      end
    end

  end

  class Item < Struct.new(:label, :url, :sub_items, :options)

    def initialize(label, url, options = {})
      super(label, url, [], options)
    end

    def sub_items?
      sub_items.present?
    end

    def render(template)
      template.content_tag(:li, class: css_class) do
        template.safe_join([template.link_to(label, url, options),
                            render_sub_items(template)].compact)
      end
    end

    def css_class
      'dropdown-submenu' if sub_items?
    end

    def render_sub_items(template)
      if sub_items?
        template.content_tag_nested(:ul, sub_items, class: 'dropdown-menu') do |sub|
          sub.render(template)
        end
      end
    end

  end

  class Divider
    def render(template)
      template.content_tag(:li, '', class: 'divider')
    end
  end
end
