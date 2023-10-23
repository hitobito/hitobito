# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
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
      @button_class = 'btn btn-outline-primary btn-sm'
      @items = []
    end

    def to_s
      template.content_tag(:div, class: 'btn-group dropdown') do
        render_dropdown_button +
          render_items
      end
    end

    def add_divider
      @items << Divider.new
    end

    def add_item(label, url, disabled_msg: nil, **options)
      item = Item.new(label, url, disabled_msg: disabled_msg, **options)
      @items << item
      item
    end

    def add_title(label, options = {})
      item = Title.new(label, options)
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
                    data: { 'bs_toggle': 'dropdown' }) do
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
      html_options = { class: 'dropdown-menu', role: 'menu' }
      template.content_tag_nested(:ul, items, html_options) do |item|
        item.render(template)
      end
    end

  end

  class Item
    attr_accessor :label, :url, :disabled_msg, :sub_items, :options

    def initialize(label, url, disabled_msg: nil, **options)
      @label = label
      @url = url
      @disabled_msg = disabled_msg
      @sub_items = []
      @options = options
    end

    def sub_items?
      sub_items.present?
    end

    def render(template)
      template.content_tag(:li, class: css_class) do
        template.safe_join([link(template, label, url, options),
                            render_sub_items(template)].compact)
      end
    end

    def link(template, label, url, html_options = {})
      return disabled_link(template) if disabled_msg

      new_url = case url
      when ActionController::Parameters then url.to_unsafe_h.merge(only_path: true)
      when Hash then url.merge(only_path: true)
      else url
      end

      html_options[:class] = 'dropdown-item'
      if sub_items?
        html_options[:class] += ' dropdown-toggle'
      end

      return template.link_to(label, new_url, html_options)
    end

    def disabled_link(template)
      template.content_tag(:a, class: 'dropdown-item disabled', title: disabled_msg) do
        label
      end
    end

    def css_class
      'dropdown dropend' if sub_items?
    end

    def render_sub_items(template)
      if sub_items?
        html_options = { class: 'dropdown-menu submenu', role: 'menu' }

        template.content_tag_nested(:ul, sub_items, html_options) do |sub|
          sub.render(template)
        end
      end
    end

  end

  class Divider
    def render(template)
      template.content_tag(:hr, '', class: 'dropdown-divider')
    end
  end

  Title = Struct.new(:label, :options) do
    def initialize(label, options = {})
      super(label, options)
    end

    def render(template)
      template.content_tag(:li, class: 'muted dropdown-menu-subtitle') do
        template.content_tag(:small, label, options)
      end
    end
  end
end
