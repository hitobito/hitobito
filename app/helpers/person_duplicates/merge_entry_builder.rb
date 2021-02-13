# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PersonDuplicates
  class MergeEntryBuilder
    WARNING_ICON = "⚠️"

    delegate :t, :safe_join, to: :template
    delegate :persons_valid?, to: :duplicate_entry

    def initialize(form, duplicate_entry, template)
      @f = form
      @duplicate_entry = duplicate_entry
      @template = template
    end

    def render
      safe_join([person_entry(:person_1), person_entry(:person_2)])
    end

    private

    attr_reader :f, :template, :duplicate_entry

    delegate :link_to, :group_person_path, to: :template
    delegate :person_1, :person_2, to: :duplicate_entry

    def person_entry(p_nr)
      person = send(p_nr).decorate
      radio_button_with_details(person, p_nr)
    end

    def radio_button_with_details(person, p_nr)
      selected = p_nr.eql?(:person_1)
      f.label("dst_#{p_nr}", class: label_class(selected), for: label_for(p_nr)) do
        options = {}
        if persons_valid?
          options[:checked] = selected
        else
          options[:checked] = false
          options[:disabled] = "disabled"
        end
        f.radio_button("dst_person", p_nr, options) +
          f.content_tag(:div,
            person_label(person) +
            details(person) +
            person.roles_short(nil, edit: false) +
            merge_hint(p_nr, person))
      end
    end

    def label_class(selected)
      selected && persons_valid? ? "radio selected" : "radio"
    end

    def label_for(p_nr)
      "person_duplicate_dst_person_#{p_nr}"
    end

    def person_label(person)
      link_to(person.to_s,
        group_person_path(person.primary_group, person),
        target: "_blank")
    end

    def details(person)
      detail_values(person).compact.map do |v|
        f.content_tag(:div, v, class: "label")
      end.join.html_safe
    end

    def detail_values(person)
      %w[company_name birth_year town].map do |a|
        person.send(a)
      end
    end

    def merge_hint(p_nr, person)
      return merge_hint_invalid unless person.valid?

      if persons_valid?
        style_class = ""
        style_class += " hidden" if p_nr.eql?(:person_1)
        f.content_tag(:div, id: "merge-hint", class: style_class) do
          [WARNING_ICON, t(".merge_hint")].join(" ")
        end
      else
        "".html_safe
      end
    end

    def merge_hint_invalid
      f.content_tag(:div, id: "merge-hint") do
        [WARNING_ICON, t(".merge_hint_invalid")].join(" ")
      end
    end
  end
end
