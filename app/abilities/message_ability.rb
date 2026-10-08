# frozen_string_literal: true

#  Copyright (c) 2012-2026, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class MessageAbility < AbilityDsl::Base
  on(Message) do
    permission(:layer_and_below_full)
      .may(:create)
      .in_layer_or_below_if_active

    permission(:layer_and_below_full)
      .may(:show)
      .in_layer_or_below

    permission(:layer_and_below_full)
      .may(:edit, :update, :destroy)
      .in_layer_or_below_if_not_dispatched_nor_bulkmail

    permission(:any)
      .may(:show)
      .if_assignment_assignee_or_creator
  end

  def if_assignment_assignee_or_creator
    any_of({assignments: {person_id: user.id}}, {assignments: {creator_id: user.id}}) if user.id
  end

  def in_layer_or_below
    group_condition(lft: below_layers(user_layer_ids))
  end

  def in_layer_or_below_if_active
    group_condition(lft: below_layers(user_layer_ids), archived_at: nil)
  end

  def in_layer_or_below_if_not_dispatched_nor_bulkmail
    all_of(not_bulk_mail, in_layer_or_below_if_active, {state: "draft"})
  end

  def not_bulk_mail
    none_of(type: sti_names([Message::BulkMail, *Message::BulkMail.descendants]))
  end

  private

  def group_condition(condition)
    {mailing_list: {group: condition}}
  end
end
