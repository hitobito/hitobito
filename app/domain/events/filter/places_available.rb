# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class PlacesAvailable
    def initialize(_user, params, _options, scope)
      @params = params
      @scope  = scope
    end

    def to_scope
      return @scope unless only_available?

      @scope.places_available
    end

    private

    def only_available?
      @params.dig(:filter, :places_available).to_i == 1
    end
  end
end
