module Sheet
  class Event
    class ApplicationMarket < Sheet::Base
      self.parent_sheet = Sheet::Event
    end
  end
end