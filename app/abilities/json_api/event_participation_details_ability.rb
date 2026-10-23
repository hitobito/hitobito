# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module JsonApi
  class EventParticipationDetailsAbility < EventParticipationAbility
    self.event_role_permissions = [:participations_read_details, :participations_full]
    self.layer_and_below_permissions = [:layer_and_below_full]
    self.group_and_below_permissions = [:group_and_below_full]
    self.layer_permissions = [:layer_full]
    self.group_permissions = [:group_full]
    self.include_visible_participations = false
    self.include_pending_applications = false

    private

    def define_abilities_from_service_token_or_person
      super

      # The details of a participation are only readable for normal users with a _full
      # permission or a corresponding event role. A service token has no event roles, and
      # requiring a write (_full) permission for reading participant data would be unintuitive.
      # So we allow service tokens with the event_participations scope separately, on the
      # events of their permitted groups.
      if token&.event_participations?
        can_read_if(event: {groups: {id: token.permitted_groups.pluck(:id)}})
      end
    end

    def token = user.service_token
  end
end
