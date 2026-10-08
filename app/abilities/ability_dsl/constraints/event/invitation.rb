# frozen_string_literal: true

#  Copyright (c) 2021-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl::Constraints::Event
  module Invitation
    include AbilityDsl::Constraints::Event

    def own_invitation
      {person_id: user.id} if user.id
    end

    def in_same_group_and_invitations_supported
      all_of(in_same_group, invitations_supported)
    end

    def in_same_group_or_below_and_invitations_supported
      all_of(in_same_group_or_below, invitations_supported)
    end

    def in_same_layer_and_invitations_supported
      all_of(in_same_layer, invitations_supported)
    end

    def in_same_layer_or_below_and_invitations_supported
      all_of(in_same_layer_or_below, invitations_supported)
    end

    private

    def invitations_supported
      event_condition(type: sti_names(::Event.all_types.select(&:supports_invitations)))
    end
  end
end
