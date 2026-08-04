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
  end
end
