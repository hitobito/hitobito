# frozen_string_literal: true

# Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
# hitobito_youth and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito_youth.

# Most of the time, managers inherit a fixed list of abilities from their manageds.
# But sometimes, we need to check whether the manager would be allowed something
# even if they weren't a manager. In the youth wagon, we override the default
# ability class to take the inherited abilities into account. This ability class here
# allows us to revert back to the core behaviour in the few places where we need it.
class AbilityWithoutManagerAbilities < Ability
  private

  def define_user_abilities(current_store, current_user_context)
    super(current_store, current_user_context, false)
  end
end
