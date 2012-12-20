module Subscriber
  class Person < Base
    
    class << self
      def available(group)
        # All people for all groups available
        Person.scoped
      end
    end
    
    def people
      [subscriber]
    end
    
  end
end