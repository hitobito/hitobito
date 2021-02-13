#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingList::Subscribers

  delegate :id, :subscriptions, to: "@list"

  def initialize(mailing_list, people_scope = Person.only_public_data)
    @list = mailing_list
    @people_scope = people_scope
  end

  def people
    @people_scope.
      joins(people_joins).
      joins(subscription_joins).
      where(subscriptions: { mailing_list_id: id }).
      where("people.id NOT IN (#{excluded_subscriber_ids.to_sql})").
      where("people.id NOT IN (#{tag_excluded_person_ids.to_sql})").
      where(suscriber_conditions).
      distinct
  end

  def people_joins
    sql = <<~SQL
      LEFT JOIN roles ON people.id = roles.person_id
      LEFT JOIN #{Group.quoted_table_name} ON roles.group_id = #{Group.quoted_table_name}.id
    SQL

    if subscriptions.events.exists?
      sql += <<~SQL
        LEFT JOIN event_participations ON event_participations.person_id = people.id
      SQL
    end

    if subscriptions.groups.any?(&:subscription_tags)
      sql += <<~SQL
        LEFT JOIN taggings AS people_taggings ON people_taggings.taggable_type = 'Person'
          AND people_taggings.taggable_id = people.id
      SQL
    end

    sql
  end

  def subscription_joins
    sql = ", subscriptions " # the comma is needed because it is not a JOIN, but a second "FROM"

    if subscriptions.groups.exists?
      sql += <<~SQL
        LEFT JOIN #{Group.quoted_table_name} sub_groups
          ON subscriptions.subscriber_type = 'Group' AND subscriptions.subscriber_id = sub_groups.id
        LEFT JOIN related_role_types
          ON related_role_types.relation_type = 'Subscription'
          AND related_role_types.relation_id = subscriptions.id
      SQL
    end

    if subscriptions.groups.any?(&:subscription_tags)
      sql += <<~SQL
        LEFT JOIN subscription_tags
          ON subscription_tags.subscription_id = subscriptions.id
      SQL
    end

    sql
  end

  def suscriber_conditions
    condition = OrCondition.new
    person_subscribers(condition) if subscriptions.people.exists?
    event_subscribers(condition) if subscriptions.events.exists?
    group_subscribers(condition) if subscriptions.groups.exists?
    condition.to_a
  end

  def person_subscribers(condition)
    condition.or("subscriptions.subscriber_type = ? AND " \
                 "subscriptions.excluded = ? AND " \
                 "subscriptions.subscriber_id = people.id",
                 Person.sti_name,
                 false)
  end

  def group_subscribers(condition)
    sql = <<~SQL
      subscriptions.subscriber_type = ? AND
      #{Group.quoted_table_name}.lft >= sub_groups.lft AND
      #{Group.quoted_table_name}.rgt <= sub_groups.rgt AND
      roles.type = related_role_types.role_type AND
      roles.deleted_at IS NULL
    SQL

    if subscriptions.groups.any?(&:subscription_tags)
      sql += <<~SQL
        AND (subscription_tags.tag_id IS NULL OR
        subscription_tags.tag_id = people_taggings.tag_id)
      SQL
    end

    condition.or(sql, Group.sti_name)
  end

  def event_subscribers(condition)
    condition.or("subscriptions.subscriber_type = ? AND " \
                 "subscriptions.subscriber_id = event_participations.event_id AND " \
                 "event_participations.active = ?",
                 Event.sti_name,
                 true)
  end

  private

  def tag_excluded_person_ids
    ActsAsTaggableOn::Tagging.select(:taggable_id)
                             .where(taggable_type: Person.sti_name,
                                    tag_id: tag_excluded_subscription_ids)
  end

  def tag_excluded_subscription_ids
    SubscriptionTag.select(:tag_id)
                   .joins(:subscription)
                   .where(subscription_tags: { excluded: true },
                                             subscriptions: { mailing_list_id: id })
  end

  def excluded_subscriber_ids
    Subscription.select(:subscriber_id).
      where(mailing_list_id: id,
            excluded: true,
            subscriber_type: Person.sti_name)
  end
end
