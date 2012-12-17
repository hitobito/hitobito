module Sheet
  class Event
    class Participation < Base
      self.parent_sheet = Sheet::Event
    end
  end
end