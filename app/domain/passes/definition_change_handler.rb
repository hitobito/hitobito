#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Passes
  class DefinitionChangeHandler
    SYNC_ATTRIBUTES = %w[name description template_key background_color].freeze

    def initialize(pass_definition)
      @pass_definition = pass_definition
    end

    # Called from PassDefinition's after_update callback.
    # Marks all active wallet installations for re-sync when display attributes change.
    def handle_update
      return unless sync_needed?

      @pass_definition.pass_memberships.eligible.find_each do |pass_membership|
        pass_membership.pass_installations.each do |installation|
          Wallets::PassSynchronizer.new(installation).mark_for_sync!
        end
      end
    end

    private

    def sync_needed?
      (@pass_definition.saved_changes.keys & SYNC_ATTRIBUTES).any?
    end
  end
end
