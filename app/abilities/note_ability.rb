# encoding: utf-8

#  Copyright (c) 2012-2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class NoteAbility < AbilityDsl::Base

  on(Note) do
    permission(:layer_full).
      may(:create, :show, :destroy).
      in_same_layer

    permission(:layer_and_below_full).
      may(:create, :show, :destroy).
      in_same_layer_or_below
  end

  def in_same_layer
    case subj
    when Group then permission_in_layer?(subj.layer_group_id)
    when Person then permission_in_layers?(subj.layer_group_ids)
    else raise(ArgumentError, "Unknown note subject #{subj.class}")
    end
  end

  def in_same_layer_or_below
    case subj
    when Group then permission_in_layers?(subj.layer_hierarchy.collect(&:id))
    when Person then permission_in_layers?(subj.groups_hierarchy_ids)
    else raise(ArgumentError, "Unknown note subject #{subj.class}")
    end
  end

  private

  def subj
    subject.subject
  end

end
