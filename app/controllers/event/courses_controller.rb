class Event::CoursesController < EventsController
  self.nesting_optional = true

  class << self
    def model_class
      Event::Course
    end
  end

end
