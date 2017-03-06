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

    permission(:group_full).
      may(:approve, :reject).
      non_restricted_or_deleted_in_same_group
    permission(:group_and_below_full).
      may(:approve, :reject).
      non_restricted_or_deleted_in_same_group_or_below
    permission(:layer_full).
      may(:approve, :reject).
      non_restricted_or_deleted_in_same_layer
    permission(:layer_and_below_full).
      may(:approve, :reject).
      non_restricted_or_deleted_in_same_layer_or_visible_below

    # This does not tell if people actually may be added, just if they may be added to some body,
    # that no request is required. Basically, this is possible if the user may already show the
    # person.
    permission(:any).may(:add_without_request).herself
    permission(:contact_data).may(:add_without_request).other_with_contact_data
    permission(:group_read).may(:add_without_request).in_same_group
    permission(:group_and_below_read).may(:add_without_request).in_same_group_or_below
    permission(:layer_read).may(:add_without_request).in_same_layer
    permission(:layer_and_below_read).may(:add_without_request).in_same_layer_or_below
    permission(:group_full).
      may(:add_without_request).
      active_or_deleted_in_same_group
    permission(:group_and_below_full).
      may(:add_without_request).
      active_or_deleted_in_same_group_or_below
    permission(:layer_full).
      may(:add_without_request).
      active_or_deleted_in_same_layer
    permission(:layer_and_below_full).
      may(:add_without_request).
      active_or_deleted_in_same_layer_or_below
  end

  def her_own
    user.id == subject.requester_id
  end

  def non_restricted_or_deleted_in_same_group
    non_restricted_in_same_group || deleted_in_same_group
  end

  def non_restricted_or_deleted_in_same_group_or_below
    non_restricted_in_same_group || deleted_in_same_group_or_below
  end

  def non_restricted_or_deleted_in_same_layer
    non_restricted_in_same_layer || deleted_in_same_layer
  end

  def non_restricted_or_deleted_in_same_layer_or_visible_below
    non_restricted_in_same_layer_or_visible_below || deleted_in_same_layer_or_below
  end

  def active_or_deleted_in_same_group
    in_same_group || deleted_in_same_group
  end

  def active_or_deleted_in_same_group_or_below
    in_same_group_or_below || deleted_in_same_group_or_below
  end

  def active_or_deleted_in_same_layer
    in_same_layer || deleted_in_same_layer
  end

  def active_or_deleted_in_same_layer_or_below
    in_same_layer_or_below || deleted_in_same_layer_or_below
  end

  private

  def person
    subject.person
  end

  def deleted_in_same_group
    role = person.last_non_restricted_role
    role && permission_in_group?(role.group_id)
  end

  def deleted_in_same_group_or_below
    role = person.last_non_restricted_role
    role && permission_in_group?(role.group.local_hierarchy.collect(&:id))
  end

  def deleted_in_same_layer
    role = person.last_non_restricted_role
    role && permission_in_layer?(role.group.layer_group_id)
  end

  def deleted_in_same_layer_or_below
    role = person.last_non_restricted_role
    role && permission_in_layers?(role.group.hierarchy.collect(&:id))
  end

end
