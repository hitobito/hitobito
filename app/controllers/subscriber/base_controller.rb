# encoding: UTF-8
module Subscriber

  class BaseController < CrudController

    self.nesting = Group, MailingList

    decorates :group

    before_filter :authorize!
    
    prepend_before_filter :parent

    def create
      super(location: group_mailing_list_subscriptions_path(@group, @mailing_list))
    end


    private

    alias_method :mailing_list, :parent
    
    def assign_attributes
      if subscriber_id
        entry.subscriber = subscriber
        entry.excluded = false
      end
    end
    
    def subscriber_id
      model_params && model_params[:subscriber_id].presence
    end
    
    def subscriber
      # implement in subclass
    end
    
    def replace_validation_errors
      default_base_errors.each do |attr, old, msg|
        if entry.errors[attr].first == old
          entry.errors.clear
          entry.errors.add(:base, msg)
        end
      end
    end

    def default_base_errors
      [[:subscriber_type, "muss ausgefüllt werden", "#{model_label} muss ausgewählt werden"],
       [:subscriber_id, 'ist bereits vergeben', "#{model_label} wurde bereits hinzugefügt"]]
    end

    def authorize!
      super(:create, @subscription || @mailing_list.subscriptions.new)
    end
    
    class << self
      def model_class
        Subscription
      end
    end

  end
end
