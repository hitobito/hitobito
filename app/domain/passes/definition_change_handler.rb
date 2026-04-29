# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Passes
  class DefinitionChangeHandler
    # Attributes that affect the visual appearance of wallet passes.
    # When these change, all active wallet installations must be re-synced
    # to reflect the updated pass design.
    SYNC_ATTRIBUTES = %w[name description template_key background_color].freeze

    def initialize(pass_definition)
      @pass_definition = pass_definition
    end

    # Called from PassDefinition's after_update callback.
    # Marks all active wallet installations for re-sync when display attributes change.
    def handle_update
      return unless sync_needed?

      Wallets::PassInstallation
        .joins(:pass)
        .where(passes: {pass_definition_id: @pass_definition.id, state: "eligible"})
        .active
        .update_all(needs_sync: true)
    end

    private

    # Checks if any visual attributes changed that require wallet re-sync.
    # Returns true if any SYNC_ATTRIBUTES were modified in the last save.
    def sync_needed?
      (@pass_definition.saved_changes.keys & SYNC_ATTRIBUTES).any?
    end
  end
end
