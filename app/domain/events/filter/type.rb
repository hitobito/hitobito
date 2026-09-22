# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class Type < Base
    self.permitted_args = [:types]

    def apply(scope)
      scope.where(type: persisted_types)
    end

    def requested_types
      args[:types].to_a.map(&:to_s)
    end

    private

    def persisted_types
      requested_types.map do |type|
        type unless type == "Event" # regular events set type=nil
      end
    end
  end
end
