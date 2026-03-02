#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Passes
  class PassMembershipUpdater
    def initialize(person, role)
      @person = person
      @role = role
    end

    def run
      return unless @person.pass_memberships.exists?

      affected = Wallets::PassEligibility.affected_pass_memberships(@person, role: @role)
      return unless affected.any?

      affected.find_each do |membership|
        recompute_state!(membership)
        mark_installations_for_sync!(membership)
      end
    end

    private

    def recompute_state!(membership)
      pass = Pass.new(person: @person, definition: membership.pass_definition)

      if pass.eligible?
        membership.update!(state: :eligible, valid_from: pass.valid_from, valid_until: pass.valid_until)
      elsif pass.has_ended?
        membership.update!(state: :ended, valid_from: pass.valid_from, valid_until: pass.valid_until)
      else
        membership.update!(state: :revoked)
      end
    end

    def mark_installations_for_sync!(membership)
      membership.pass_installations.each do |installation|
        Wallets::PassSynchronizer.new(installation).mark_for_sync! unless installation.revoked?
      end
    end
  end
end
