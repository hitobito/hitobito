module AbilityDsl::Constraints::Event
  module Participation

    def her_own
      participation.person_id == user.id
    end

    def for_applicant_in_same_layer
      confirm_layer_ids = user_context.layer_ids(user.groups_with_permission(:approve_applications))
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

  end
end