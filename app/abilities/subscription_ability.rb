# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SubscriptionAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(Subscription) do
    permission(:any).may(:manage).her_own
    permission(:group_full).may(:manage).in_same_group
    permission(:group_and_below_full).may(:manage).in_same_group_or_below
    permission(:layer_full).may(:manage).in_same_layer
    permission(:layer_and_below_full).may(:manage).in_same_layer

    general.group_not_deleted_or_archived
  end

  def her_own
    list = subject.mailing_list
    list.subscribable? && subject.subscriber == user
  end

  private

  def group
    subject.mailing_list.group
  end
end
