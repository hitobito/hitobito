# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonDuplicateAbility < AbilityDsl::Base

  on(PersonDuplicate) do
    permission(:any).may(:merge).if_processible
    permission(:any).may(:ignore).if_processible
  end

  def if_processible
    not_ignored && read_write_on_person
  end

  def read_write_on_person
    persons = [subject.person_1, subject.person_2]
    persons.all? { |p| person_ability_can?(:show, p) } &&
      persons.any? { |p| person_ability_can?(:update, p) }
  end

  def not_ignored
    !subject.ignore
  end

  private

  def person_ability_can?(action, person)
    Ability.new(user).can?(action, person)
  end

end
