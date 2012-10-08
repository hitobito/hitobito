class EventsController < CrudController

  self.nesting = Group
  
  decorates :event

  # load group before authorization
  prepend_before_filter :parent
  
end
