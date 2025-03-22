# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Subscriptions
  attr_reader :scope

  def initialize(person, scope = MailingList)
    @person = person
    @scope = scope
  end

  def create(mailing_list)
    change_subscription(mailing_list, false)
  end
  alias_method :subscribe, :create

  def destroy(mailing_list)
    change_subscription(mailing_list, true)
  end
  alias_method :unsubscribe, :destroy

  def subscribed
    scope
      .where(id: direct_inclusions.select("mailing_list_id"))
      .or(scope.anyone.or(scope.configured.opt_out).or(scope.nobody).merge(from_group_or_events))
      .where.not(id: direct_exclusions.select("mailing_list_id"))
      .where.not(id: globally_excluding_mailing_list_ids)
  end

  def subscribable
    scope.anyone
      .or(
        scope.configured.merge(from_group_or_events)
             .where(id: direct_exclusions.or(scope.opt_in).select("mailing_list_id"))
      )
      .where.not(id: subscribed.map(&:id))
      .where.not(id: globally_excluding_mailing_list_ids)
      .distinct
  end

  private

  def globally_excluding_mailing_list_ids
    @globally_excluding_mailing_list_ids ||= Person::Subscriptions::GlobalExclusions.new(@person.id)
      .excluding_mailing_list_ids
  end

  def change_subscription(mailing_list, excluded)
    # first clean out existing contradictory subscriptions
    mailing_list.subscriptions.where(subscriber: @person, excluded: !excluded).destroy_all

    # then create new subscription if not matching the exclude value
    if subscription_needs_change?(mailing_list, excluded)
      mailing_list.subscriptions.create!(subscriber: @person, excluded:)
    end
  end

  # is true if current `subscribed?` state does not match value of `excluded`
  # (person is subscribed but should be excluded or vice versa)
  def subscription_needs_change?(mailing_list, excluded)
    mailing_list.subscribed?(@person) == excluded
  end

  def from_events
    Subscription.events
      .where(subscriber_id: @person.event_participations.active.select("event_id"))
      .left_joins(:subscription_tags)
      .where(subscription_tags_condition, @person.tag_ids)
      .where.not(id: tag_excluded_subscription_ids)
  end

  def from_groups
    return Subscription.none if @person.roles.without_archived.blank?

    sql = <<~SQL.squish
      related_role_types.role_type = ? AND
      #{Group.quoted_table_name}.lft <= ? AND
      #{Group.quoted_table_name}.rgt >= ? AND
      #{subscription_tags_condition}
    SQL

    condition = OrCondition.new
    @person.roles.without_archived.each do |role|
      condition.or(sql, role.type, role.group.lft, role.group.rgt, @person.tag_ids)
    end

    Subscription
      .groups
      .joins("INNER JOIN #{Group.quoted_table_name} ON " \
             "#{Group.quoted_table_name}.id = subscriptions.subscriber_id")
      .joins(:related_role_types)
      .left_joins(:subscription_tags)
      .where(condition.to_a)
      .where.not(id: tag_excluded_subscription_ids)
  end

  def from_group_or_events
    scope
      .where(id: from_events.select("mailing_list_id"))
      .or(scope.where(id: from_groups.select("mailing_list_id")))
  end

  def subscription_tags_condition
    "subscription_tags.tag_id IS NULL OR " \
      "(subscription_tags.excluded <> true AND subscription_tags.tag_id IN (?))"
  end

  def tag_excluded_subscription_ids
    SubscriptionTag.excluded.where(tag_id: @person.tag_ids).select(:subscription_id)
  end

  def direct_inclusions
    @direct_inclusions ||= @person.subscriptions.where(excluded: false)
  end

  def direct_exclusions
    @direct_exclusions ||= @person.subscriptions.where(excluded: true)
  end
end
