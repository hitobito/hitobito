#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Subscriptions

  def initialize(person)
    @person = person
  end

  def mailing_lists
    scope = MailingList

    scope
      .where(id: direct.select('mailing_list_id'))
      .or(scope.where(id: from_events.select('mailing_list_id')))
      .or(scope.where(id: from_groups.select('mailing_list_id')))
      .where.not(id: exclusions.select('mailing_list_id'))
      .distinct
  end

  def direct
    @person.subscriptions.where(excluded: false)
  end

  def exclusions
    @person.subscriptions.where(excluded: true)
  end

  def from_events
    event_ids = @person.event_participations.active.select('event_id')
    Subscription.events.where(subscriber_id: event_ids)
  end

  def from_groups
    sql = <<~SQL
      related_role_types.role_type = ? AND
      groups.lft <= ? AND groups.rgt >= ? AND
      (tags.name IS NULL OR tags.name IN (?))
    SQL

    condition = OrCondition.new
    @person.roles.each do |role|
      condition.or(sql, role.type, role.group.lft, role.group.rgt, @person.tag_list)
    end

    Subscription
      .groups
      .joins('INNER JOIN groups ON groups.id = subscriptions.subscriber_id')
      .joins(:related_role_types)
      .left_joins(:tags)
      .where(condition.to_a)
  end
end
