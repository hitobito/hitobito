# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl::Constraints::Event
  # Conditions on the participation of the subject, see #participation_condition.
  module Participation
    def her_own_or_for_participations_read_details_events
      any_of(her_own, for_participations_read_details_events)
    end

    def her_own_or_for_participations_full_events
      any_of(her_own, for_participations_full_events)
    end

    def in_same_layer_or_different_prio
      any_of(in_same_layer, different_prio)
    end

    def in_same_layer_or_below_or_different_prio
      any_of(in_same_layer_or_below, different_prio)
    end

    def her_own
      if user.id
        participation_condition(participant_id: user.id,
          participant_type: ::Person.sti_name)
      end
    end

    def for_applicant_in_same_layer
      approval_groups = user.groups_with_permission(:approve_applications)
      confirm_layer_ids = user_context.layer_ids(approval_groups)
      return if confirm_layer_ids.blank?

      all_of(with_application,
        participation_condition(participant_type: ::Person.sti_name,
          participant_id: people_in_or_below_layers(confirm_layer_ids)))
    end

    private

    # Nests a condition on a participation under the association of the subject
    # leading to the participation.
    def participation_condition(condition)
      condition
    end

    def event_condition(condition)
      participation_condition(nested(:event, condition))
    end

    def with_application
      none_of(participation_condition(application_id: nil))
    end

    # Pending applications which may be shown in courses other than their first priority.
    def different_prio
      return unless contains_any?(user_layer_ids, user_context.course_offerers)

      all_of(participation_condition(active: false),
        with_application,
        none_of(participation_condition(
          application: {waiting_list: false, priority_2_id: nil, priority_3_id: nil}
        )))
    end

    def people_in_or_below_layers(layer_ids)
      ::Person.joins(roles: :group).where(groups: {lft: below_layers(layer_ids)}).select(:id)
    end
  end
end
