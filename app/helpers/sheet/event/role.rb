module Sheet
  class Event
    class Role < Sheet::Base
      self.parent_sheet = Sheet::Event
    end
  end
end