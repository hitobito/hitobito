# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PersonDuplicates
  class MergeEntryBuilder

    def initialize(form, duplicate_entry, template)
      @f = form
      @duplicate_entry = duplicate_entry
      @template = template
    end

    def render
      [person_entry(:person_1), person_entry(:person_2)].join.html_safe
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
      f.label("dst_#{p_nr}", class: label_class(selected)) do
        options = { checked: selected }
        f.radio_button('dst_person', p_nr, options) +
          f.content_tag(:div,
            person_label(person) +
            details(person) +
            person.roles_short(nil, edit: false)
          )
      end
    end

    def label_class(selected)
      selected ? 'radio selected' : 'radio'
    end

    def person_label(person)
      if person.primary_group
        link_to(person.to_s,
                group_person_path(person.primary_group, person),
                target: '_blank')
      else
        person.to_s
      end
    end

    def details(person)
      %w[company_name birth_year town].collect do |a|
        person.send(a)
      end.compact.map do |detail|
        f.content_tag(:div, detail, class: 'label')
      end.join.html_safe
    end

  end
end
