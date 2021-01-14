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
    @exclusions ||= @person.subscriptions.where(excluded: true)
                           .or(Subscription.where(id: exclusions_by_subscription_tags))
  end

  def from_events
    event_ids = @person.event_participations.active.select('event_id')
    Subscription.events.where(subscriber_id: event_ids)
  end

  def from_groups
    sql = <<~SQL
      related_role_types.role_type = ? AND
      #{Group.quoted_table_name}.lft <= ? AND
      #{Group.quoted_table_name}.rgt >= ? AND
      (subscription_tags.tag_id IS NULL OR (subscription_tags.excluded <> true AND subscription_tags.tag_id IN (?)))
    SQL

    condition = OrCondition.new
    @person.roles.each do |role|
      condition.or(sql, role.type, role.group.lft, role.group.rgt, @person.tag_ids)
    end

    Subscription
      .groups
      .joins("INNER JOIN #{Group.quoted_table_name} ON " \
             "#{Group.quoted_table_name}.id = subscriptions.subscriber_id")
      .joins(:related_role_types)
      .left_joins(:subscription_tags)
      .where(condition.to_a)
      .where.not(id: exclusions.pluck(:id))
  end

  private

  def exclusions_by_subscription_tags
    SubscriptionTag.where(tag_id: @person.tag_ids, excluded: true).pluck(:subscription_id)
  end
end
