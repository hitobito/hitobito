# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl::Constraints::Event
  module Participation
    def her_own_or_for_participations_full_events
      her_own || for_participations_full_events
    end

    def in_same_layer_or_different_prio
      in_same_layer || different_prio
    end

    def in_same_layer_or_below_or_different_prio
      in_same_layer_or_below || different_prio
    end

    def her_own
      participation.person_id == user.id
    end

    def for_applicant_in_same_layer
      approval_groups = user.groups_with_permission(:approve_applications)
      confirm_layer_ids = user_context.layer_ids(approval_groups)
      participation.application_id? &&
        confirm_layer_ids.present? &&
        contains_any?(confirm_layer_ids, participation.person.groups_hierarchy_ids)
    end

    private

    def event
      participation.event
    end

    def participation
      subject.participation
    end

    def different_prio
      return false if participation.active? || !participation.application_id?

      # This is a bit more than really needed, to restrict further we would
      # need the actual course the participation should be displayed for,
      # which we do not have.
      appl = participation.application
      (appl.waiting_list? || appl.priority_2_id? || appl.priority_3_id?) &&
        permission_in_layers?(course_offerers)
    end

    def course_offerers
      @course_offerers ||= Group.course_offerers.pluck(:id)
    end
  end
end
