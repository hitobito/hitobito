# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::InactivityBlockWarningJob < RecurringJob
  def perform
    return unless Person::BlockService.warn?

    Person::BlockService.warn_scope.find_each do |person|
      Person::BlockService.new(person).inactivity_warning!
    end
    true
  end

end
