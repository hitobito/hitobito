#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class TableDisplays < Base

    delegate :form_tag, :hidden_field_tag, :label_tag, :check_box_tag, :content_tag,
             :content_tag_nested, :table_displays_path, :parent, :current_person, :t,
             :dom_id, to: :template

    def initialize(template, list)
      super(template, template.t('global.columns'), :bars)
      first = list.first
      @table_model_class = first.try(:decorated?) ? first.model.class.to_s : first.class.to_s
      @list = list
    end

    def to_s
      return unless Settings.table_displays

      content_tag(:div, html_options) do
        form_tag(table_displays_path(format: :js), remote: true) do
          render_table_model_class_field + super
        end
      end
    end

    private

    def render_table_model_class_field
      hidden_field_tag('table_model_class', @table_model_class)
    end

    def render_items
      options = { class: 'dropdown-menu pull-right', data: { persistent: true }, role: 'menu' }

      content_tag(:ul, options) do
        items = table_display.available(@list).collect do |column|
          render_item('selected[]', table_display.column_for(column), column)
        end

        safe_join(items)
      end
    end

    def render_item(name, column, value, label = render_label(column, value))
      content_tag(:li) do
        check_box_tag(name, value, selected?(value), id: value, data: { submit: true }) +
          label_tag(value, label)
      end
    end

    def selected?(value)
      table_display.selected.include?(value)
    end

    def table_display
      @table_display ||= current_person.table_display_for(@table_model_class)
    end

    def render_label(column, attr)
      column.label(attr)
    end

    def html_options
      {
        id: dom_id(parent),
        class: 'table-display-dropdown',
        data: { turbolinks_permanent: 1 }
      }
    end

  end
end
