# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterNavigation
  class Base
    include Translatable

    attr_reader :template, :main_items, :dropdown, :active_label

    delegate :content_tag, :link_to, to: :template

    def initialize(template)
      @template = template
      @main_items = []
      @active_label = nil
      @dropdown = Dropdown.new(template)
    end

    def to_s
      content_tag(:div, class: 'toolbar-pills mb-2') do
        content_tag(:ul, class: 'nav nav-pills group-pills border border-light rounded') do
          template.safe_join([*main_items, dropdown_item])
        end
      end
    end

    private

    def dropdown_item
      if dropdown.items.present?
        content_tag(:li,
                    class: "dropdown nav-link border-start border-light
                      rounded-0 py-0 px-3 #{'active' if dropdown.active}"
                   ) do
          template.in_button_group { dropdown.to_s }
        end
      end
    end

    def item(label, url, count = nil)
      caption = count ? "#{label} (#{count})" : label
      @main_items << content_tag(:li,
                                 link_to(caption, url, class: "nav-link rounded-0 py-1 px-3
                                         mr-0 #{'active' if active_label == label}"),
                                 class: 'nav-item border-start border-light')
    end

  end

  class Dropdown < Dropdown::Base

    attr_accessor :active

    def initialize(template)
      super(template, translate(:additional_views))
      @active = false
      @button_class = nil
    end

    def activate(label)
      self.label = label
      self.active = true
    end
  end
end
