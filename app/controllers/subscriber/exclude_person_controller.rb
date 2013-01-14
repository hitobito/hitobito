# encoding: UTF-8
module Subscriber
  class ExcludePersonController < PersonController
    
    skip_authorize_resource # must be in leaf class
    
    before_create :assert_subscribed

    private

    def assign_attributes
      super
      entry.excluded = true
    end
    
    def assert_subscribed
      if subscriber_id
        unless mailing_list.subscribed?(subscriber)
          entry.errors.add(:base, "#{subscriber.to_s} ist kein Abonnent")
          false
        end
      end
    end
    
    def save_entry
      if subscriber_id
        @mailing_list.exclude_person(subscriber)
      else
        super
      end
    end
    
    def flash_message(state)
      if state == :success
        "Abonnent #{subscriber} wurde erfolgreich ausgeschlossen"
      else 
        super
      end
    end

  end
end
