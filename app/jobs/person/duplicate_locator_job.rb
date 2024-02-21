# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

class Person::DuplicateLocatorJob < BaseJob
  self.parameters = [:person_id]

  def initialize(person_id)
    @person_id = person_id
  end

  def perform
    People::DuplicateLocator.new(Person.where(id: @person_id)).run
  end
end
