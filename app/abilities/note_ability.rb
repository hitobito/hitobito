# frozen_string_literal: true

#  Copyright (c) 2012-2026, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class NoteAbility < AbilityDsl::Base
  on(Note) do
    permission(:layer_full).may(:show).in_same_layer
    permission(:layer_full).may(:create, :destroy).in_same_layer_if_active

    permission(:layer_and_below_full).may(:show).in_same_layer_or_below
    permission(:layer_and_below_full).may(:create, :destroy).in_same_layer_or_below_if_active
  end

  def in_same_layer
    note_subjects_in(layer_group_id: user_layer_ids)
  end

  def in_same_layer_if_active
    note_subjects_in({layer_group_id: user_layer_ids}, archived_at: nil)
  end

  def in_same_layer_or_below
    note_subjects_in(lft: below_layers(user_layer_ids))
  end

  def in_same_layer_or_below_if_active
    note_subjects_in({lft: below_layers(user_layer_ids)}, archived_at: nil)
  end

  private

  def note_subjects_in(groups, subject_group_conditions = {})
    any_of(
      {subject_type: Group.polymorphic_name,
       subject_id: Group.where(groups).where(subject_group_conditions).select(:id)},
      {subject_type: Person.polymorphic_name,
       subject_id: Person.joins(roles: :group).where(groups: groups).select(:id)}
    )
  end
end
