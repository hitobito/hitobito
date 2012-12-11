module MailRelay
  module ManualDestinations
    
    def destinations
      @destinations || []
    end
    
    def destinations=(destinations)
      @destinations = destinations
    end
    
  end
end