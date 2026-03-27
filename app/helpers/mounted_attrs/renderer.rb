# frozen_string_literal: true

#  Copyright (c) 2023-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MountedAttrs
  class Renderer
    def initialize(entry, template)
      @entry = entry
      @template = template
    end

    def render
      return if attrs_by_category.empty?

      content = +"" # keep this particular string mutable as we collect data in it.
      attrs_by_category.each do |c, configs|
        content << content_tag(:h2, category_label(c))
        content << render_attrs(entry, *configs.map(&:attr_name))
      end
      content.html_safe
    end

    private

    attr_reader :template, :entry
    delegate :content_tag, :t, :render_attrs, to: :template

    def attrs_by_category
      entry.model.class.mounted_attr_configs_by_category
    end

    def category_label(category)
      t("mounted_attributes.form_tabs.#{entry.model.class.sti_name.underscore}.#{category}")
    end
  end
end
