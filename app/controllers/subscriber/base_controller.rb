module Subscriber
  class BaseController < CrudController
    
    self.nesting = Group, MailingList
    
    prepend_before_filter :parent
    
    def create
      super(location: group_mailing_list_subscriptions_path(@group, @mailing_list))
    end
    
    
    def authorize!(action, *args)
      super(:create, @subscription || @mailing_list.subscriptions.new)
    end
    
    private
    
    alias_method :mailing_list, :parent
    
    
    class << self
      def model_class
        Subscription
      end
    end
    
  end
end