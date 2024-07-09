# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class HouseholdMember
  include ActiveModel::Model

  attr_reader :person, :household

  validates_with Households::MemberValidator

  def self.from(people, household)
    members = people.collect { |p| new(p, household) }
    ref_person_id = household.reference_person.id
    members.sort_by { |m| (m.person.id == ref_person_id) ? 0 : 1 }
  end

  def initialize(person, household)
    @person = person
    @household = household
  end

  def warnings
    @warnings ||= ActiveModel::Errors.new(self)
  end
end
