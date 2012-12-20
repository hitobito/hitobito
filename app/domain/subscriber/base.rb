module Subscriber
  class Base
        
    attr_reader :subscription
    
    delegate :subscriber, to: :subscription
        
    class << self
    
      def for(subscription)
        clazz = "Subscriber::#{subscription.subscriber_type}".constantize
        clazz.new(subscription)
      end
    end
    
    def initialize(subscription)
      @subscription = subscription
    end
    
  end
end