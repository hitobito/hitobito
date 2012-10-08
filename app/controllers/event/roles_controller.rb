class Event::RolesController < CrudController
  
  
  class << self
    def model_class
      Event::Role
    end
  end
  
end