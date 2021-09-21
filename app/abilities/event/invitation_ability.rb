# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::InvitationAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Event

  on(Event::Invitation) do
    permission(:group_full).
      may(:new, :create, :edit).
      in_same_group
    permission(:group_and_below_full).
      may(:new, :create, :edit).
      in_same_group_or_below
    permission(:layer_full).
      may(:new, :create, :edit).
      in_same_group
    permission(:layer_and_below_full).
      may(:new, :create, :edit).
      in_same_group_or_below

    permission(:any).may(:decline).own_invitation
  end

  def own_invitation
    subject.person_id == user_context.user.id
  end
end
