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
      return @scope if valid_state.blank?

      @scope.where(state: valid_state)
    end

    private

    def requested_state
      @params.dig(:filter, :state).to_s
    end

    def valid_state
      @valid_state ||= ([requested_state] & possible_states).first
    end

    def possible_states
      @possible_states ||= Event::Course.possible_states.map(&:to_s)
    end
  end
end
