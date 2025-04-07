# frozen_string_literal: true

#  Copyright (c) 2024, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingLists::Subscribers
  attr_reader :people_scope

  delegate :id, :filter_chain, :subscriptions, :subscribable_for_configured?, :opt_in?, to: "@list"

  def initialize(mailing_list = MailingList.first, people_scope = Person.only_public_data)
    @list = mailing_list
    @people_scope = people_scope
  end

  def people
    scope.distinct
  end

  def scope
    return people_as_configured unless opt_in?

    people_as_configured.where(id: subscriptions.people.included.select("subscriber_id"))
  end

  def subscribed?(person)
    subscribed = people_as_configured.where(id: person.id).exists? && unfiltered_people_as_configured.present?
    return subscribed unless opt_in? && subscribable_for_configured?

    subscribed && subscriptions.people.where(id: person.id).exists?
  end

  def people_as_configured
    filter_chain.filter(people_scope.merge(unfiltered_people_as_configured))
  end

  private

  def unfiltered_people_as_configured
    conditions = OrCondition.new
    conditions.or("group_subscriptions.role_type = roles.type")
    conditions.or("event_subscriptions.subscriber_id IS NOT NULL and event_participations.active = ?", true)
    conditions.or("people.id = person_including_subscriptions.subscriber_id") if use_people_subscriptions?

    people_scope
      .with(person_tag_ids: person_tag_ids)
      .with(group_subscriptions: group_subscriptions)
      .with(event_subscriptions: event_subscriptions)
      .with(person_including_subscriptions: person_including_subscriptions)
      .with(person_excluding_subscriptions: person_excluding_subscriptions)
      .left_joins(:taggings)
      .left_joins(roles: :group)
      .left_joins(:event_participations)
      .joins("LEFT OUTER JOIN group_subscriptions ON groups.lft >= group_subscriptions.lft AND groups.rgt <= group_subscriptions.rgt")
      .joins("LEFT OUTER JOIN event_subscriptions ON event_subscriptions.subscriber_id = event_participations.event_id ")
      .joins("LEFT OUTER JOIN person_including_subscriptions ON people.id = person_including_subscriptions.subscriber_id")
      .joins("LEFT OUTER JOIN person_excluding_subscriptions ON people.id = person_excluding_subscriptions.subscriber_id")
      .joins("LEFT OUTER JOIN person_tag_ids ON people.id = person_tag_ids.person_id")
      .where(roles: {archived_at: [[nil], Time.zone.now..]})
      .where("array_length(including_tag_ids, 1) IS NULL OR including_tag_ids && person_tag_ids")
      .where("array_length(excluding_tag_ids, 1) IS NULL OR array_length(person_tag_ids, 1) IS NULL OR NOT(excluding_tag_ids && person_tag_ids)")
      .where(conditions.to_a)
      .where(person_excluding_subscriptions: {subscriber_id: nil})
  end

  def group_subscriptions = Subscription.groups
    .with(including_tags: subscription_tags(excluded: false))
    .with(excluding_tags: subscription_tags(excluded: true))
    .joins(:related_role_types)
    .where(mailing_list: id)
    .joins("INNER JOIN groups ON groups.id = subscriptions.subscriber_id")
    .joins("LEFT OUTER JOIN excluding_tags ON excluding_tags.subscription_id = subscriptions.id")
    .joins("LEFT OUTER JOIN including_tags ON including_tags.subscription_id = subscriptions.id")
    .select("groups.lft, groups.rgt, related_role_types.role_type, excluding_tags.tag_ids AS excluding_tag_ids, including_tags.tag_ids as including_tag_ids")

  def subscription_tags(excluded:)
    SubscriptionTag
      .select("subscription_id, array_agg(tag_id) AS tag_ids")
      .where(excluded:)
      .group(:subscription_id)
  end

  def person_tag_ids
    ActsAsTaggableOn::Tagging
      .select("taggable_id as person_id, array_agg(tag_id) as person_tag_ids")
      .where(taggable_type: "Person")
      .group(:taggable_id)
  end

  def event_subscriptions = Subscription.events.where(mailing_list_id: id)

  def person_including_subscriptions = Subscription.people.included.where(mailing_list_id: id)

  def person_excluding_subscriptions = Subscription.people.excluded.where(mailing_list_id: id)

  def use_people_subscriptions? = !(opt_in? && subscribable_for_configured?)
end
