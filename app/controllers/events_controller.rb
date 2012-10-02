class EventsController < CrudController

  self.nesting = Group

  # load group before authorization
  prepend_before_filter :parent
  
end
