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
      radio_button(person, p_nr) +
        details(person) +
        person.roles_short(nil, edit: false)
    end

    def radio_button(person, p_nr)
      f.label("dst_#{p_nr}", class: 'radio') do
        checked = p_nr.eql?(:person_1)
        options = { checked: checked }
        f.radio_button("dst_person", p_nr, options) +
          person_label(person)
      end
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
      end.compact.join(' / ')
    end

  end
end
