module Sheet
  class Event
    class Qualification < Sheet::Base
      self.parent_sheet = Sheet::Event
    end
  end
end