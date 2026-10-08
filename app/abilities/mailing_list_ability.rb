# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Group

  on(::MailingList) do
    class_side(:index).everybody
    permission(:any).may(:show).subscribable

    permission(:group_full).may(:show, :index_subscriptions).in_same_group
    permission(:group_full)
      .may(:create, :update, :update_subscriptions, :destroy)
      .in_same_group_if_active
    permission(:group_full)
      .may(:export_subscriptions)
      .in_same_group_if_no_subscriptions_in_below_groups

    permission(:group_and_below_full).may(:show, :index_subscriptions).in_same_group_or_below
    permission(:group_and_below_full)
      .may(:create, :update, :update_subscriptions, :destroy)
      .in_same_group_or_below_if_active
    permission(:group_and_below_full)
      .may(:export_subscriptions)
      .in_same_group_or_below_if_no_subscriptions_in_below_layers

    permission(:layer_full).may(:show, :index_subscriptions).in_same_layer
    permission(:layer_full)
      .may(:create, :update, :update_subscriptions, :destroy)
      .in_same_layer_if_active
    permission(:layer_full)
      .may(:export_subscriptions)
      .in_same_layer_if_no_subscriptions_in_below_layers

    permission(:layer_and_below_full)
      .may(:show, :index_subscriptions, :export_subscriptions)
      .in_same_layer
    permission(:layer_and_below_full)
      .may(:create, :update, :update_subscriptions, :destroy)
      .in_same_layer_if_active

    general.group_not_deleted
  end

  on(Imap::Mail) do
    permission(:admin).may(:manage).if_mail_config_present
  end

  on(Bounce) do
    class_side(:index).if_admin

    permission(:admin).may(:manage).if_mail_config_present
  end

  def if_mail_config_present
    {} if Settings.email.retriever.config.present?
  end

  def in_same_group_if_no_subscriptions_in_below_groups
    all_of(in_same_group, with_local_subscriptions)
  end

  def in_same_group_or_below_if_no_subscriptions_in_below_layers
    all_of(in_same_group_or_below, with_local_subscriptions)
  end

  def in_same_layer_if_no_subscriptions_in_below_layers
    all_of(in_same_layer, with_local_subscriptions)
  end

  def subscribable
    current_user = user
    {id: AbilityDsl::LazyRelation.new do
      Person::Subscriptions.new(current_user).subscribable.unscope(:select).select(:id)
    end}
  end

  private

  def with_local_subscriptions
    local_subscriptions = MailingLists::LocalSubscriptions.new(permission)
    {id: AbilityDsl::LazyRelation.new { local_subscriptions.lists.select(:id) }}
  end
end
