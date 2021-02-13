#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class TableDisplays < Base
    delegate :form_tag, :hidden_field_tag, :label_tag, :check_box_tag, :content_tag,
      :content_tag_nested, :table_displays_path, :parent, :current_person, :t,
      :dom_id, to: :template

    def initialize(template)
      super(template, template.t("global.columns"), :bars)
    end

    def to_s
      return unless Settings.table_displays

      content_tag(:div, html_options) do
        form_tag(table_displays_path(format: :js), remote: true) do
          render_parent_fields + super
        end
      end
    end

    private

    def render_parent_fields
      hidden_field_tag("parent_id", parent.id) +
        hidden_field_tag("parent_type", parent.class.base_class)
    end

    def render_items
      options = {class: "dropdown-menu pull-right", data: {persistent: true}, role: "menu"}

      content_tag(:ul, options) do
        items = table_display.available.collect { |column|
          render_item("selected[]", column)
        }

        items += event_specific_items if parent.is_a?(::Event)
        safe_join(items)
      end
    end

    def render_item(name, column, value = column, label = render_label(column))
      content_tag(:li) do
        check_box_tag(name, value, selected?(value), id: value, data: {submit: true}) +
          label_tag(value, label)
      end
    end

    def event_specific_items
      render_questions(:application) + render_questions(:admin) + unrelated_hidden_questions
    end

    def render_questions(kind)
      questions = present_questions(kind)
      return [] if questions.empty?

      divider = Divider.new.render(template)
      title = Title.new(t("event.participations.#{kind}_answers")).render(template)

      questions.collect { |question|
        render_item("selected[]", question.label, dom_id(question), question.label)
      }.prepend(divider, title)
    end

    def present_questions(kind)
      parent.questions.send(kind).select { |q| q.question.present? }
    end

    def unrelated_hidden_questions
      table_display.selected.collect do |column|
        next unless column =~ TableDisplay::Participations::QUESTION_REGEX
        next if parent.question_ids.include?(Regexp.last_match(1).to_i)
        hidden_field_tag("selected[]", column)
      end
    end

    def selected?(value)
      table_display.selected.include?(value)
    end

    def table_display
      @table_display ||= current_person.table_display_for(parent)
    end

    def render_label(column)
      ::TableDisplays::Column.new(self, name: column).label
    end

    def html_options
      {
        id: dom_id(parent),
        class: "table-display-dropdown",
        data: {turbolinks_permanent: 1},
      }
    end
  end
end
