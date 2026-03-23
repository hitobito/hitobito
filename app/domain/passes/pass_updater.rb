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

    def role = @role

    private

    def recompute_state!(pass)
      Passes::StateCalculator.new(pass.pass_definition, person).update_state!(pass)
    end

    def mark_installations_for_sync!(pass)
      pass.pass_installations.each do |installation|
        Wallets::PassSynchronizer.new(installation).mark_for_sync! unless installation.revoked?
      end
    end
  end
end
