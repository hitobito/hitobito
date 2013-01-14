# encoding: utf-8
class SubscriptionsController < CrudController
  
  self.nesting = Group, MailingList
  
  decorates :group
  
  prepend_before_filter :parent
  
  alias_method :mailing_list, :parent
  
  def authorize!(action, *args)
    if :index == action
      super(:index_subscriptions, mailing_list)
    else
      super
    end
  end

  def index
    @group_subs = get_group_subscriptions
    @person_subs = get_person_subscriptions
    @event_subs = get_event_subscriptions
    @excluded_person_subs = get_person_subscriptions(true)
  end

  private

  def get_group_subscriptions
    mailing_list.subscriptions.where(subscriber_type: 'Group').
      joins('inner join groups on groups.id = subscriptions.subscriber_id').
      order('groups.name').
      includes(:subscriber, :mailing_list, :related_role_types)
  end

  def get_person_subscriptions(excluded = false)
    mailing_list.subscriptions.where(subscriber_type: 'Person', excluded: excluded).
      joins('inner join people on people.id = subscriptions.subscriber_id').
      order('people.last_name', 'people.first_name').
      includes(:subscriber, :mailing_list)
  end

  def get_event_subscriptions
    mailing_list.subscriptions.where(subscriber_type: 'Event').
      joins('inner join events on events.id = subscriptions.subscriber_id').
      order('events.name').
      includes(:subscriber, :mailing_list)
  end

end
