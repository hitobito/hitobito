# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class Dropdown < Dropdown::Base

    delegate :form_tag, :hidden_field_tag, :label_tag, :check_box_tag, :content_tag,
             :content_tag_nested, :table_displays_path, :parent, :current_person, :t, to: :template

    def initialize(template)
      super(template, template.t('global.columns'), :bars)
    end

    def to_s
      content_tag(:div, id: 'table-display-dropdown', data: { turbolinks_permanent: 1 }) do
        form_tag(table_displays_path(format: :js), remote: true) do
          render_parent_fields + super
        end
      end
    end

    private

    def render_parent_fields
      hidden_field_tag('parent_id', parent.id) +
        hidden_field_tag('parent_type', parent.class.base_class)
    end

    def render_items
      options = { class: 'dropdown-menu pull-right', data: { persistent: true }, role: 'menu' }

      content_tag_nested(:ul, table_display.available, options) do |column|
        content_tag(:li) do
          render_item('selected[]', column)
        end
      end
    end

    def render_item(name, column)
      check_box_tag(name, column, selected?(column), id: column, data: { submit: true }) +
        label_tag(column, render_label(column))
    end

    def selected?(column)
      table_display.selected.include?(column)
    end

    def table_display
      @table_display ||= current_person.table_display_for(parent)
    end

    def render_label(column)
      TableDisplays::Column.new(self, name: column).label
    end
  end
end
