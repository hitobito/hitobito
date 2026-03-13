# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class PlacesAvailable < Filter::Base
    self.permitted_args = [:value]

    def apply(scope)
      scope.places_available
    end

    def blank?
      args[:value].to_i != 1
    end
  end
end
