# frozen_string_literal: true

#  Copyright (c) 2012-2024, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::DuplicateLocatorJob < RecurringJob
  self.parameters = [:people_ids]
  run_every 1.day

  def initialize(people_ids = nil)
    super()
    @people_scope = Person.where(id: people_ids) if people_ids
  end

  def perform
    if @people_scope
      locator = People::DuplicateLocator.new(@people_scope)
    else
      locator = People::DuplicateLocator.new
    end
    locator.run
  end

end
