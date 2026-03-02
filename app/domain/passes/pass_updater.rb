# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Passes
  # Updates pass state and wallet installations when a person's role changes.
  # Called from Role callbacks (after_create, after_update, after_destroy) to
  # recalculate pass eligibility and sync wallet passes accordingly.
  class PassUpdater
    def initialize(role)
      @role = role
    end

    # Recomputes and persists state + validity dates for a single pass.
    # Extracted as a class method so it can be called without a role context
    # (e.g. from PassPopulateJob).
    def self.recompute_state!(pass)
      calculator = Passes::StateCalculator.new(pass.pass_definition, pass.person)
      dates = calculator.validity_dates
      # valid_from must never be blank (DB constraint). When no role carries a
      # start_on, preserve whatever the pass already has — or default to today
      # if this is the first time we're setting it.
      dates[:valid_from] ||= pass.valid_from || Date.current
      pass.update!(state: calculator.state, **dates)
    end

    def run
      return unless person.passes.exists?

      affected = Passes::Subscribers.affected_passes(person, role:)
      return unless affected.any?

      affected.find_each do |pass|
        recompute_state!(pass)
        mark_installations_for_sync!(pass)
      end
    end

    def person = role.person

    attr_reader :role

    private

    delegate :recompute_state!, to: :class

    def mark_installations_for_sync!(pass)
      pass.pass_installations.where.not(state: :revoked).update_all(needs_sync: true)
    end
  end
end
