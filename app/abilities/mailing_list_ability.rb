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
    permission(:group_full).
      may(:export_subscriptions).
      in_same_group_if_no_subscriptions_in_below_groups

    permission(:group_and_below_full).
      may(:index_subscriptions, :create, :update, :destroy).
      in_same_group_or_below
    permission(:group_and_below_full).
      may(:export_subscriptions).
      in_same_group_or_below_if_no_subscriptions_in_below_layers

    permission(:layer_full).may(:index_subscriptions, :create, :update, :destroy).in_same_layer
    permission(:layer_full).
      may(:export_subscriptions).
      in_same_layer_if_no_subscriptions_in_below_layers

    permission(:layer_and_below_full).
      may(:index_subscriptions, :export_subscriptions, :create, :update, :destroy).in_same_layer

    general.group_not_deleted
  end

  def in_same_group_if_no_subscriptions_in_below_groups
    in_same_group && no_subscriptions_below
  end

  def in_same_group_or_below_if_no_subscriptions_in_below_layers
    in_same_group_or_below && no_subscriptions_below
  end

  def in_same_layer_if_no_subscriptions_in_below_layers
    in_same_layer && no_subscriptions_below
  end

  def no_subscriptions_below
    !group_subscriptions_with_below_role_types? &&
      local_event_subscription_count == total_event_subscription_count
  end

  private

  def group_subscriptions_with_below_role_types?
    subject.subscriptions.
      where(subscriber_type: 'Group').
      joins(:related_role_types).
      where.not(related_role_types: { role_type: local_role_types.collect(&:sti_name) }).
      exists?
  end

  def local_role_types
    case permission
    when :group_full
      group.class.role_types
    when :group_and_below_full
      local_group_role_types(group.class)
    when :layer_full
      local_group_role_types(group.layer_group.class)
    else
      fail('Unexpected permission')
    end
  end

  def local_group_role_types(group_type)
    list = Role::TypeList.new(group_type)
    list.role_types[group_type.label].values.flatten
  end

  def total_event_subscription_count
    subject.subscriptions.
      where(subscriber_type: 'Event').
      count
  end

  def local_event_subscription_count
    subject.subscriptions.
      where(subscriber_type: 'Event').
      joins('INNER JOIN events ON subscriptions.subscriber_id = events.id').
      joins('INNER JOIN events_groups ON events_groups.event_id = events.id').
      where(events_groups: { group_id: local_group_ids }).
      uniq.
      count
  end

  def local_group_ids
    case permission
    when :group_full
      subject.group_id
    when :group_and_below_full
      group.self_and_descendants.where(layer_group_id: group.layer_group_id)
    when :layer_full
      group.groups_in_same_layer
    else
      fail('Unexpected permission')
    end
  end

end
