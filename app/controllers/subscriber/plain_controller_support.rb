module Subscriber
  module PlainControllerSupport

    def self.included(controller_class)
      controller_class.before_filter :custom_authorization
    end

    private

    def custom_authorization
      authorize!(:manage, subscription)
    end

    def subscription
      @subscription ||= (find_subscription || build_subscription)
    end

    def build_subscription
      subscription = mailing_list.subscriptions.build
      subscription.subscriber = person
      subscription
    end

    def find_subscription
      if person
        conditions = {subscriber_id: person.id, subscriber_type: Person.sti_name }.merge(extra_find_conditions)
        mailing_list.subscriptions.where(conditions).first
      end
    end

    def extra_find_conditions
      {}
    end

    def mailing_list
      @mailing_list ||= MailingList.find(params[:mailing_list_id])
    end

    def mailing_list_path
      group_mailing_list_path(group_id: mailing_list.group.id, id: mailing_list.id)
    end

    def success_message(key)
      postfix = { subscribed: "erstellt", unsubscribed: "ausgeschlossen" }
      "#{Subscription.model_name.human} #{person} wurde erfolgreich #{postfix[key]}"
    end

  end
end
