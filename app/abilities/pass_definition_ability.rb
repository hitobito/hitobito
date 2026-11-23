#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PassDefinitionAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Group

  on(PassDefinition) do
    class_side(:index).everybody

    permission(:group_full).may(:show, :index_pass_grants).in_same_group
    permission(:group_full)
      .may(:create, :update, :destroy)
      .in_same_group_if_active

    permission(:group_and_below_full).may(:show, :index_pass_grants).in_same_group_or_below
    permission(:group_and_below_full)
      .may(:create, :update, :destroy)
      .in_same_group_or_below_if_active

    permission(:layer_full).may(:show, :index_pass_grants).in_same_layer
    permission(:layer_full)
      .may(:create, :update, :destroy)
      .in_same_layer_if_active

    permission(:layer_and_below_full)
      .may(:show, :index_pass_grants)
      .in_same_layer
    permission(:layer_and_below_full)
      .may(:create, :update, :destroy)
      .in_same_layer_if_active

    general.group_not_deleted
  end

  def group
    subject.owner
  end
end
