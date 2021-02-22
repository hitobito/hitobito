#  frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class MessageAbility < AbilityDsl::Base
  on(Message) do
    permission(:layer_and_below_full)
      .may(:create, :show)
      .in_layer_or_below
    permission(:layer_and_below_full)
      .may(:edit, :update, :destroy)
      .in_layer_or_below_if_not_dispatched
    permission(:any)
      .may(:show)
      .if_assignment_assignee_or_creator
  end

  def if_assignment_assignee_or_creator
    subject.assignments.any? { |a| [a.person_id, a.creator_id].include?(user.id) }
  end

  def in_layer_or_below
    permission_in_layers?(subject.group.layer_hierarchy.collect(&:id))
  end

  def in_layer_or_below_if_not_dispatched
    in_layer_or_below && !subject.dispatched?
  end
end
