# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Person

  on(Person::AddRequest) do
    permission(:any).may(:approve, :reject).herself
    permission(:any).may(:reject).her_own

    permission(:layer_full).may(:approve, :reject).non_restricted_in_same_layer
    permission(:layer_and_below_full).
      may(:approve, :reject).
      non_restricted_in_same_layer_or_visible_below

    permission(:group_full).may(:add_without_request).in_same_group
    permission(:group_and_below_full).may(:add_without_request).in_same_group_or_below
    permission(:layer_full).may(:add_without_request).in_same_layer
    permission(:layer_and_below_full).may(:add_without_request).in_same_layer_or_below
  end

  def her_own
    user.id == subject.requester_id
  end

  private

  def person
    subject.person
  end

end
