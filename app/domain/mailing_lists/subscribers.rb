# frozen_string_literal: true

#  Copyright (c) 2024, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingLists::Subscribers
  delegate :id, :filter_chain, :subscriptions, :subscribable_for_configured?, :opt_in?, to: "@list"

  OuterJoin = Arel::Nodes::OuterJoin

  def initialize(mailing_list, people_scope = Person.only_public_data)
    @list = mailing_list
    @people_scope = people_scope
    @now = Time.zone.now
  end

  def people
    scope.distinct
  end

  def subscribed?(person)
    subscribed = filter_chain.filter(Person.where(id: person.id)).exists? &&
      Person.connection.select_values(people_cte.where(Arel::Table.new(:people)[:id].eq(person.id)).to_sql).present?
    return subscribed unless opt_in? && subscribable_for_configured?

    subscribed && subscriptions.people.where(id: person.id).exists?
  end

  def people_as_configured
    filter_chain.filter(@people_scope.where(id: Person.find_by_sql(people_cte.to_sql)))
  end

  def person_subscribers(condition)
    condition.or("subscriptions.subscriber_type = ? AND " \
                   "subscriptions.excluded = ? AND " \
                   "subscriptions.subscriber_id = people.id",
                 Person.sti_name,
                 false)
  end

  def group_subscribers(condition)
    sql = <<~SQL.split.join(" ")
      subscriptions.subscriber_type = ? AND
      #{Group.quoted_table_name}.lft >= sub_groups.lft AND
      #{Group.quoted_table_name}.rgt <= sub_groups.rgt AND
      roles.type = related_role_types.role_type AND
      (roles.start_on IS NULL OR
       roles.start_on <= '#{@time.to_date.to_fs(:db)}') AND
      (roles.end_on IS NULL OR
       roles.end_on >= '#{@time.to_date.to_fs(:db)}') AND
      (roles.archived_at IS NULL OR
       roles.archived_at > '#{@time.to_time.utc.to_fs(:db)}')
    SQL

    if subscriptions.groups.any?(&:subscription_tags)
      sql += <<~SQL.split.join(" ")
        AND (subscription_tags.tag_id IS NULL OR
        subscription_tags.tag_id = people_taggings.tag_id)
      SQL
    end

    condition.or(sql, Group.sti_name)
  end

  def join_events?
    opt_in? || subscriptions.events.exists?
  end

  def join_tags?
    subscriptions.groups.any?(&:subscription_tags)
  end

  def join_groups?
    opt_in? || subscriptions.groups.exists?
  end

  def event_subscribers(condition)
    condition
      .or("subscriptions.subscriber_type = ? AND " \
            "subscriptions.subscriber_id = event_participations.event_id AND " \
            "event_participations.active = ?",
          Event.sti_name,
          true)
  end

  def tag_excluded_person_ids
    ActsAsTaggableOn::Tagging
      .select(:taggable_id)
      .where(taggable_type: Person.sti_name,
             tag_id: tag_excluded_subscription_ids)
  end

  def tag_excluded_subscription_ids
    SubscriptionTag
      .select(:tag_id).joins(:subscription)
      .where(subscription_tags: { excluded: true }, subscriptions: { mailing_list_id: id })
  end

  def excluded_subscriber_ids
    Subscription
      .select(:subscriber_id)
      .where(mailing_list_id: id, excluded: true, subscriber_type: Person.sti_name)

  end

  private

  def scope
    return people_as_configured unless opt_in?

    people_as_configured.where(id: subscriptions.people.included.select("subscriber_id"))
  end

  attr_reader :list, :today, :now

  def people_cte(columns = [:id])
    people = Arel::Table.new(:people)
    groups = Arel::Table.new(:groups)
    roles = Arel::Table.new(:roles)
    taggings = Arel::Table.new(:taggings)

    group_subscriptions = Arel::Table.new(:group_subscriptions)
    event_subscriptions = Arel::Table.new(:event_subscriptions)
    including_person_subscriptions = Arel::Table.new(:including_person_subscriptions)
    excluding_person_subscriptions = Arel::Table.new(:excluding_person_subscriptions)

    ctes = [Arel::Nodes::As.new(:group_subscriptions, group_subscriptions_cte)]
    ctes += [Arel::Nodes::As.new(:event_subscriptions, event_participations_cte)] if event_subscriptions?
    ctes += [Arel::Nodes::As.new(:including_person_subscriptions, including_person_subscriptions_cte)] if including_people_subscriptions?
    ctes += [Arel::Nodes::As.new(:excluding_person_subscriptions, excluding_person_subscriptions_cte)] if excluding_people_subscriptions?

    conditions = group_subscriptions[:role_type].not_eq(nil)
                                                .then { |scope| event_subscriptions? ? scope.or(event_subscriptions[:person_id].not_eq(nil)) : scope }
                                                .then { |scope| including_people_subscriptions? ? scope.or(including_person_subscriptions[:subscriber_id].not_eq(nil)) : scope }
                                                .then { |scope| excluding_people_subscriptions? ? scope.and(excluding_person_subscriptions[:subscriber_id].eq(nil)) : scope }
                                                .then do |scope|
      next scope unless group_subscription_tags?
      scope.and(group_subscriptions[:tag_id].eq(nil)
                                            .or(group_subscriptions[:tag_excludes].eq(false).and(group_subscriptions[:tag_id].eq(taggings[:tag_id])))
                                            .or(group_subscriptions[:tag_excludes].eq(true).and(taggings[:tag_id].eq(nil).or(taggings[:tag_id].not_eq(group_subscriptions[:tag_id])))))
    end

    Person
      .select(*columns)
      .left_joins(roles: :group)
      .arel
      .join(taggings, OuterJoin).on(taggings[:taggable_id].eq(people[:id]).and(taggings[:taggable_type].eq(Person.sti_name)))
      .join(group_subscriptions, Arel::Nodes::OuterJoin).on(
      groups[:lft].gteq(group_subscriptions[:lft])
                  .and(groups[:rgt].lteq(group_subscriptions[:rgt]))
                  .and(roles[:type].eq(group_subscriptions[:role_type]))
                  .and(roles[:start_on].eq(nil).or(roles[:start_on].lteq(now.to_date)))
                  .and(roles[:end_on].eq(nil).or(roles[:end_on].gteq(now.to_date)))
                  .and(roles[:archived_at]).eq(nil).or(roles[:archived_at].gteq(now))
    )
      .then { |scope| event_subscriptions? ? scope.join(event_subscriptions, OuterJoin).on(event_subscriptions[:person_id].eq(people[:id])) : scope }
      .then { |scope| including_people_subscriptions? ? scope.join(including_person_subscriptions, OuterJoin).on(including_person_subscriptions[:subscriber_id].eq(people[:id])) : scope }
      .then { |scope| excluding_people_subscriptions? ? scope.join(excluding_person_subscriptions, OuterJoin).on(excluding_person_subscriptions[:subscriber_id].eq(people[:id])) : scope }
      .with(*ctes)
      .where(conditions)
  end

  def subscriptions_cte(excluded:)
    table = Arel::Table.new(:subscriptions)
    table
      .where(table[:mailing_list_id].eq(id))
      .where(table[:excluded].eq(excluded))
      .where(table[:subscriber_type].eq(Person.sti_name))
      .project(table[:subscriber_id])
  end

  def group_subscriptions_cte
    groups = Arel::Table.new(:groups)
    related_role_types = Arel::Table.new(:related_role_types)
    subscriptions = Arel::Table.new(:subscriptions)
    subscription_tags = Arel::Table.new(:subscription_tags)
    projections = [groups[:lft], groups[:rgt], related_role_types[:role_type]]
    projections += [subscription_tags[:tag_id], subscription_tags[:excluded].as("tag_excludes")] if group_subscription_tags?

    groups
      .project(*projections)
      .from(subscriptions)
      .join(groups).on(groups[:id].eq(subscriptions[:subscriber_id]).and(subscriptions[:subscriber_type].eq(Group.sti_name)))
      .join(related_role_types).on(related_role_types[:relation_type].eq(Subscription.sti_name).and(related_role_types[:relation_id].eq(subscriptions[:id])))
      .then { |scope| group_subscription_tags? ? scope.join(subscription_tags, OuterJoin).on(subscription_tags[:subscription_id].eq(subscriptions[:id])) : scope }
      .where(subscriptions[:mailing_list_id].eq(id))
  end

  def event_participations_cte
    participations = Arel::Table.new(:event_participations)
    subscriptions = Arel::Table.new(:subscriptions)
    participations
      .join(subscriptions).on(subscriptions[:subscriber_id].eq(participations[:event_id]).and(subscriptions[:subscriber_type].eq(Event.sti_name)))
      .where(participations[:active].eq(true))
      .where(subscriptions[:mailing_list_id].eq(id))
      .project(participations[:person_id])
  end

  def excluding_person_subscriptions_cte = subscriptions_cte(excluded: true)

  def including_person_subscriptions_cte = subscriptions_cte(excluded: false)

  def use_people_subscriptions? = memoize(:use_people_subscriptions) { !(opt_in? && subscribable_for_configured?) }

  def including_people_subscriptions? = memoize(:including_people_subscriptions) { use_people_subscriptions? && subscriptions.people.included.exists? }

  def excluding_people_subscriptions? = memoize(:excluding_people_subscriptions) { use_people_subscriptions? && subscriptions.people.excluded.exists? }

  def event_subscriptions? = memoize(:event_subscriptions) { subscriptions.events.included.exists? }

  def group_subscription_tags? = memoize(:group_subscription_tag) { subscriptions.groups.included.joins(:subscription_tags).exists? }

  def memoize(name, &block)
    ivar = "@#{name}"
    instance_variable_defined?(ivar) ? instance_variable_get(ivar) : instance_variable_set(ivar, block.call)
  end
end
