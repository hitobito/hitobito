# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class State < Base
    self.permitted_args = [:states]

    def apply(scope)
      scope.where(state: valid_states)
    end

    def blank?
      valid_states.blank?
    end

    private

    def valid_states
      @valid_states ||= (requested_states & possible_states)
    end

    def requested_states
      args[:states].to_a.map(&:to_s)
    end

    def possible_states
      return [] unless event_type.respond_to?(:possible_states)

      event_type.possible_states.map(&:to_s)
    end
  end
end
