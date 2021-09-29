# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(::MailingList) do
    permission(:any).may(:show).subscribable

    permission(:group_full).may(:show, :index_subscriptions).in_same_group
    permission(:group_full).may(:create, :update, :destroy).in_same_group_if_active
    permission(:group_full).
      may(:export_subscriptions).
      in_same_group_if_no_subscriptions_in_below_groups

    permission(:group_and_below_full).may(:show, :index_subscriptions).in_same_group_or_below
    permission(:group_and_below_full).may(:create, :update, :destroy)
                                     .in_same_group_or_below_if_active
    permission(:group_and_below_full).
      may(:export_subscriptions).
      in_same_group_or_below_if_no_subscriptions_in_below_layers

    permission(:layer_full).may(:show, :index_subscriptions).in_same_layer
    permission(:layer_full).may(:create, :update, :destroy).in_same_layer_if_active
    permission(:layer_full).
      may(:export_subscriptions).
      in_same_layer_if_no_subscriptions_in_below_layers

    permission(:layer_and_below_full).may(:show, :index_subscriptions, :export_subscriptions)
                                     .in_same_layer
    permission(:layer_and_below_full).may(:create, :update, :destroy).in_same_layer_if_active

    general.group_not_deleted
  end

  on(Imap::Mail) do
    permission(:admin).may(:manage).if_mail_config_present
  end

  def if_mail_config_present
    Settings.email.retriever.config.present?
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

  def subscribable
    subject.subscribable
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
      raise('Unexpected permission')
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
      distinct.
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
      raise('Unexpected permission')
    end
  end

end
