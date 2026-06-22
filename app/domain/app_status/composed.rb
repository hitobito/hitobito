# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AppStatus::Composed
  def initialize(*statuses)
    @statuses = statuses
  end

  def details
    @statuses.map(&:details).reduce(:merge)
  end

  def code
    @statuses.map(&:code).all?(AppStatus::OK) ? AppStatus::OK : AppStatus::SERVICE_UNAVAILABLE
  end
end
