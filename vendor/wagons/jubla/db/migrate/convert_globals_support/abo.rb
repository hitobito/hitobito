class AboMigrator < RelationMigrator
  def current_relations
    Subscription
      .joins(:related_role_types)
      .where(subscriber_type: 'Group')
      .where(related_role_types: { role_type: role_type})
  end

  def handle(subscription)
    group = subscription.subscriber
    other_role_types = subscription.role_types - [role_type.to_s]
    
    { mailing_list_id: subscription.mailing_list_id,
      subscriber_id: subscriber_for(group),
      role_types: other_role_types + role_types_for(group) }
  end

  def build(attrs)
    role_types = attrs.fetch(:role_types)
    if role_types.present?
      sub = MailingList.find(attrs.fetch(:mailing_list_id)).subscriptions.build
      sub.subscriber_type = 'Group'
      sub.subscriber_id = attrs.fetch(:subscriber_id)
      role_types.each { |role_type| sub.related_role_types.build(role_type: role_type) }
      sub
    end
  end
end
