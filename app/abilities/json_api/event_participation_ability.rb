# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module JsonApi
  class EventParticipationAbility
    include CanCan::Ability

    class_attribute :event_role_permissions, default: [:participations_read,
      :participations_read_details, :participations_full, :event_full]
    class_attribute :layer_and_below_permissions, default: [:layer_and_below_read]
    class_attribute :group_and_below_permissions, default: [:group_and_below_read]
    class_attribute :layer_permissions, default: [:layer_read]
    class_attribute :group_permissions, default: [:group_read]
    class_attribute :include_visible_participations, default: true
    class_attribute :include_pending_applications, default: true

    def initialize(user)
      @user_context = AbilityDsl::UserContext.new(user)

      define_abilities_from_person if user.id
      define_abilities_from_service_token_or_person
    end

    private

    attr_reader :user_context

    delegate :user, :course_offerers, :participations, :events_with_permission,
      :permission_layer_ids, :permission_group_ids, to: :user_context

    def define_abilities_from_person # rubocop:disable Metrics/AbcSize
      # herself
      can_read_if(participant_type: "Person", participant_id: user.id)

      # guests
      can_read_if(participant_type: "Event::Guest", participant_id: guests_for_user.select(:id))

      # managers
      can_read_if(participant_type: "Person",
        participant_id: user.people_manageds.select(:managed_id))
    end

    def define_abilities_from_service_token_or_person
      # from event roles and event.participations_visible
      can_read_if(event_id: participation_read_events)

      # from layer_and_below_* and group_and_below_* roles
      can_read_if(event: {groups: {lft: self_and_below_lft_ranges}})

      # from layer_* roles (within_layer)
      can_read_if(event: {groups: {layer_group_id: permission_layer_ids(*layer_permissions)}})

      # from group_* roles
      can_read_if(event: {groups: {id: permission_group_ids(*group_permissions)}})

      # from pending applications
      if include_pending_applications &&
          (permission_layer_ids(:layer_read, :layer_and_below_read) & course_offerers).any?
        can_read_if(active: false, application_id: pending_applications.select(:id))
      end
    end

    def can_read_if(constraints)
      can :read, ::Event::Participation, constraints
    end

    def guests_for_user = ::Event::Guest.where(main_applicant_id: active_participations.select(:id))

    def pending_applications = ::Event::Application
      .where("waiting_list IS true OR priority_2_id IS NOT NULL OR priority_3_id IS NOT NULL")

    def participation_read_events
      @participation_read_events ||= (visible_participation_events +
        event_role_permissions.flat_map { |permission| events_with_permission(permission) }).uniq
    end

    def visible_participation_events
      return [] unless include_visible_participations

      active_participations.where(events: {participations_visible: true}).pluck(:event_id)
    end

    def active_participations = user.event_participations.active.joins(:event)

    def permission_layer_ids(*permissions)
      permissions.flat_map { |permission| user_context.permission_layer_ids(permission) }
    end

    def permission_group_ids(*permissions)
      permissions.flat_map { |permission| user_context.permission_group_ids(permission) }
    end

    def self_and_below_lft_ranges
      group_ids = permission_layer_ids(*layer_and_below_permissions) +
        permission_group_ids(*group_and_below_permissions)

      Group
        .where(id: group_ids)
        .pluck(:lft, :rgt).map { |min, max| Range.new(min, max) }
    end
  end
end
