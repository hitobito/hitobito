class Person::Subscriptions

  attr_reader :scope

  def initialize(person, scope = MailingList)
    @person = person
    @scope = scope
  end

  def mailing_lists
    scope
      .where(id: direct.select('mailing_list_id'))
      .or(scope.where(id: from_events.select('mailing_list_id')))
      .or(scope.where(id: from_groups.select('mailing_list_id')))
      .where.not(id: exclusions.select('mailing_list_id'))
      .distinct
  end

  def subscribed
    scope
      .where.not(id: exclusions.select('mailing_list_id'))
      .where(id: direct.select('mailing_list_id'))
      .or(scope.merge(from_group_or_events))
      .distinct
  end

  def subscribable
    scope
      .where.not(id: direct.select('mailing_list_id'))
      .where(subscribable_for: :anyone)
      .or(scope.merge(configured(:opt_out)))
      .distinct


    # .or(configured(:opt_in))
    # .or(configured(:opt_out).where(id: exclusions.select('mailing_list_id')))
    # .distinct
  end

  def direct
    @person.subscriptions.where(excluded: false)
  end

  def exclusions
    @exclusions ||= @person.subscriptions.where(excluded: true)
                           .or(Subscription.where(id: tag_excluded_subscription_ids))
  end

  def from_events
    event_ids = @person.event_participations.active.select('event_id')
    Subscription.events.where(subscriber_id: event_ids)
  end

  def from_groups
    return Subscription.none unless @person.roles.without_archived.present?

    sql = <<~SQL
      related_role_types.role_type = ? AND
      #{Group.quoted_table_name}.lft <= ? AND
      #{Group.quoted_table_name}.rgt >= ? AND
      (subscription_tags.tag_id IS NULL OR (subscription_tags.excluded <> true AND subscription_tags.tag_id IN (?)))
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
      .where.not(id: exclusions.pluck(:id))
  end

  private

  def configured(mode)
    scope.where(subscribable_mode: mode).merge(from_group_or_events)
  end

  def tag_excluded_subscription_ids
    SubscriptionTag.where(tag_id: @person.tag_ids, excluded: true).pluck(:subscription_id)
  end

  def from_group_or_events
    scope
      .where(id: from_events.select('mailing_list_id'))
      .or(scope.where(id: from_groups.select('mailing_list_id')))
  end
end
