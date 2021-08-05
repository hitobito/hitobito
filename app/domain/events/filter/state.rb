# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class State
    def initialize(_user, params, _options, scope)
      @params = params
      @scope = scope
    end

    def to_scope
      return @scope if valid_states.blank?

      @scope.where(state: valid_states)
    end

    private

    def requested_states
      @params.dig(:filter, :states).to_a.map(&:to_s)
    end

    def valid_states
      @valid_states ||= (requested_states & possible_states)
    end

    def possible_states
      @possible_states ||= Event::Course.possible_states.map(&:to_s)
    end
  end
end
