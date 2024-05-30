# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Households::MemberValidator < ActiveModel::Validator

  delegate :person, :household, to: :'@member'
  delegate :household_key, to: :household

  def validate(household_member)
    @member = household_member
    in_other_household_present
    assert_valid_person
  end

  private

  def in_other_household_present
    if person.household_key && household_key != person.household_key
      @member.errors.add(:base,
                         :in_other_household_present,
                         person_name: person.full_name)
    end
  end

  def assert_valid_person
    unless person.valid?
      person.errors.each do |error|
        full_message = "#{person.full_name}: #{error.full_message}"
        @member.errors.add(:person, full_message)
      end
    end
  end

end
