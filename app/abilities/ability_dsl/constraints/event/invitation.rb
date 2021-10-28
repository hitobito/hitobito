# encoding: utf-8

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl::Constraints::Event
  module Invitation

    include AbilityDsl::Constraints::Event

    def own_invitation
      subject.person_id == user_context.user.id
    end

    def in_same_group_and_invitations_supported
      in_same_group && invitations_supported?
    end

    def in_same_group_or_below_and_invitations_supported
      in_same_group_or_below && invitations_supported?
    end

    def in_same_layer_and_invitations_supported
      in_same_layer && invitations_supported?
    end

    def in_same_layer_or_below_and_invitations_supported
      in_same_layer_or_below && invitations_supported?
    end

    private

    def event
      subject.event
    end

    def invitations_supported?
      event.class.supports_invitations
    end
  end
end
