module Sheet
  class Event < Base
    module Course
      class Condition < Sheet::Base
        self.parent_sheet = Sheet::Group
       
      end
    end
  end
end