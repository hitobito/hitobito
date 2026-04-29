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
      # Both CASEs return NULL when any role is open-ended on that side:
      # - start_on IS NULL means "no start constraint" → valid_from stays nil
      # - end_on IS NULL means "no expiry" → valid_until stays nil
      # SQL MIN/MAX ignore NULLs, so without the CASE they would silently
      # skip open-ended roles and produce a wrong (too late/too early) date.
      valid_from, valid_until = matching_roles.pick(
        Arel.sql("CASE WHEN BOOL_OR(start_on IS NULL) THEN NULL ELSE MIN(start_on) END"),
        Arel.sql("CASE WHEN BOOL_OR(end_on IS NULL) THEN NULL ELSE MAX(end_on) END")
      )

      {
        valid_from: valid_from&.to_date,
        valid_until: valid_until&.to_date
      }
    end

    private

    def matching_roles
      @matching_roles ||= @subscribers.matching_roles_including_ended(@person)
    end
  end
end
