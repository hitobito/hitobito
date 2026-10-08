# frozen_string_literal: true

#  Copyright (c) 2012-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Person

  on(Person::AddRequest) do # rubocop:todo Metrics/BlockLength
    permission(:any).may(:approve).herself
    permission(:any).may(:reject).herself_or_her_own

    permission(:group_full)
      .may(:approve, :reject)
      .non_restricted_or_deleted_in_same_group
    permission(:group_and_below_full)
      .may(:approve, :reject)
      .non_restricted_or_deleted_in_same_group_or_below
    permission(:layer_full)
      .may(:approve, :reject)
      .non_restricted_or_deleted_in_same_layer
    permission(:layer_and_below_full)
      .may(:approve, :reject)
      .non_restricted_or_deleted_in_same_layer_or_visible_below

    # This does not tell if people actually may be added, just if they may be added to some body,
    # that no request is required. Basically, this is possible if the user may already show the
    # person.
    permission(:any).may(:add_without_request).herself
    permission(:contact_data).may(:add_without_request).other_with_contact_data
    permission(:group_read).may(:add_without_request).in_same_group
    permission(:group_and_below_read).may(:add_without_request).in_same_group_or_below
    permission(:layer_read).may(:add_without_request).in_same_layer
    permission(:layer_and_below_read).may(:add_without_request).in_same_layer_or_below
    permission(:group_full)
      .may(:add_without_request)
      .active_or_deleted_in_same_group
    permission(:group_and_below_full)
      .may(:add_without_request)
      .active_or_deleted_in_same_group_or_below
    permission(:layer_full)
      .may(:add_without_request)
      .active_or_deleted_in_same_layer
    permission(:layer_and_below_full)
      .may(:add_without_request)
      .active_or_deleted_in_same_layer_or_below

    for_self_or_manageds do
      # Skip add requests for managers adding their manageds somewhere
      permission(:any).may(:approve).herself
      permission(:any).may(:reject).herself_or_her_own
      permission(:any).may(:add_without_request).herself
    end
  end

  def herself_or_her_own
    any_of(herself, her_own)
  end

  def her_own
    {requester_id: user.id} if user.id
  end

  def non_restricted_or_deleted_in_same_group
    any_of(non_restricted_in_same_group, deleted_in_same_group)
  end

  def non_restricted_or_deleted_in_same_group_or_below
    any_of(non_restricted_in_same_group, deleted_in_same_group_or_below)
  end

  def non_restricted_or_deleted_in_same_layer
    any_of(non_restricted_in_same_layer, deleted_in_same_layer)
  end

  def non_restricted_or_deleted_in_same_layer_or_visible_below
    any_of(non_restricted_in_same_layer_or_visible_below, deleted_in_same_layer_or_below)
  end

  def active_or_deleted_in_same_group
    any_of(in_same_group, deleted_in_same_group)
  end

  def active_or_deleted_in_same_group_or_below
    any_of(in_same_group_or_below, deleted_in_same_group_or_below)
  end

  def active_or_deleted_in_same_layer
    any_of(in_same_layer, deleted_in_same_layer)
  end

  def active_or_deleted_in_same_layer_or_below
    any_of(in_same_layer_or_below, deleted_in_same_layer_or_below)
  end

  private

  def person_condition(condition)
    nested(:person, condition)
  end

  def deleted_in_same_group
    deleted_with_last_role_in(id: user_group_ids)
  end

  def deleted_in_same_group_or_below
    deleted_with_last_role_in(any_of(*below_groups(user_group_ids)))
  end

  def deleted_in_same_layer
    deleted_with_last_role_in(layer_group_id: user_layer_ids)
  end

  def deleted_in_same_layer_or_below
    deleted_with_last_role_in(lft: below_layers(user_layer_ids))
  end

  def deleted_with_last_role_in(group_condition)
    return if group_condition.nil?

    groups = AbilityDsl::Condition.to_relation(group_condition, Group)
    {person_id: Group::DeletedPeople.last_non_restricted_role_in(groups).select(:id)}
  end
end
