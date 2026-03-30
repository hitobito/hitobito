# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module JsonApi
  class EventParticipationAbility
    include CanCan::Ability

    def initialize(ability, api_scopes: ["api"])
      @ability = ability

      return unless api_scopes.include?("event_participations") || api_scopes.include?("api")

      define_abilities_from_person
    end

    private

    attr_reader :ability

    delegate :user, :token, to: :ability
    delegate :course_offerers, :participations, :events_with_permission, :permission_layer_ids,
      :permission_group_ids, to: :"ability.user_context"

    def define_abilities_from_person # rubocop:disable Metrics/AbcSize
      if user.id
        # herself
        can_read_if(participant_type: "Person", participant_id: user.id)

        # guests
        can_read_if(participant_type: "Event::Guest", participant_id: guests_for_user.select(:id))

        # managers
        can_read_if(participant_type: "Person",
          participant_id: user.people_manageds.select(:managed_id))
      end

      # from event roles and event.participations_visible
      can_read_if(event_id: participation_read_events)

      # from layer_and_below_read and group_and_below roles (subtree)
      can_read_if(event: {groups: {lft: self_and_below_lft_ranges}})

      # from layer_read (within_layer)
      can_read_if(event: {groups: {layer_group_id: permission_layer_ids(:layer_read)}})

      # from group_read
      can_read_if(event: {groups: {id: permission_group_ids(:group_read)}})

      # from pending applications
      if (permission_layer_ids(:layer_read, :layer_and_below_read) & course_offerers).any?
        can_read_if(active: false, application_id: pending_applications.select(:id))
      end
    end

    def can_read_if(constraints)
      can :read, ::Event::Participation, constraints
    end

    def guests_for_user = ::Event::Guest.where(main_applicant_id: active_participations.select(:id))

    def pending_applications = ::Event::Application
      .where("waiting_list IS true OR priority_2_id IS NOT NULL OR priority_3_id IS NOT NULL")

    def participation_read_events =
      @participation_read_events ||=
        active_participations.where(events: {participations_visible: true}).pluck(:event_id) +
        events_with_permission(:participations_read) +
        events_with_permission(:participations_full) +
        events_with_permission(:event_full).uniq

    def active_participations = user.event_participations.active.joins(:event)

    def permission_layer_ids(*permissions)
      permissions.flat_map { |permission| ability.user_context.permission_layer_ids(permission) }
    end

    def self_and_below_lft_ranges
      group_ids = permission_layer_ids(:layer_and_below_read) +
        permission_group_ids(:group_and_below_read)

      Group
        .where(id: group_ids)
        .pluck(:lft, :rgt).map { |min, max| Range.new(min, max) }
    end

    def token_group_constraints
      if token.permission.exclude?("and_below")
        {layer_group_id: token.layer.id}
      else
        {lft: (token.layer.lft..token.layer.rgt)}
      end
    end
  end
end
