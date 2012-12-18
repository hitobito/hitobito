module Subscriber
  class Event < Base
    
    class << self
      def available(group)
        # All events of the given group available
        # TODO: restrict by date
        group.events
      end
    end
    
    def people
      subscriber.people.where(event_participations: {active: true})
    end
    
  end
end