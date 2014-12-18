# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(::MailingList) do
    permission(:any).may(:show).all
    permission(:group_full).may(:index_subscriptions, :create, :update, :destroy).in_same_group
    permission(:layer_full).may(:index_subscriptions, :create, :update, :destroy).in_same_layer
    permission(:layer_and_below_full).
      may(:index_subscriptions, :create, :update, :destroy).in_same_layer

    general.group_not_deleted
  end

end
