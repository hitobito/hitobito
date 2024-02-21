# frozen_string_literal: true

#  Copyright (c) 2012-2024, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::DuplicateLocatorJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    People::DuplicateLocator.new.run
  end
end
