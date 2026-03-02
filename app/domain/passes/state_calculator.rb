# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Passes
  # Calculates pass state and validity dates based on person's roles.
  class StateCalculator
    def initialize(pass_definition, person)
      @subscribers = Passes::Subscribers.new(pass_definition)
      @person = person
    end

    def update_state!(pass)
      pass.update!(
        state: state,
        **validity_dates
      )
    end

    # Determines the pass state based on the person's role history:
    # - :eligible - Person currently has an active matching role
    # - :ended - Person had matching roles in the past but they've ended
    # - :revoked - Person never had or no longer has any matching roles in the system
    def state
      if @subscribers.member?(@person)
        :eligible
      elsif matching_roles.exists?
        :ended
      else
        :revoked
      end
    end

    def validity_dates
      return {valid_from: nil, valid_until: nil} unless matching_roles.exists?

      {
        valid_from: matching_roles.minimum(:start_on)&.to_date || Date.current,
        valid_until: matching_roles.maximum(:end_on)&.to_date
      }
    end

    private

    def matching_roles
      @matching_roles ||= @subscribers.matching_roles_including_ended(@person)
    end
  end
end
