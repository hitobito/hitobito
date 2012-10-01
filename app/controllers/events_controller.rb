class EventsController < CrudController

  self.nesting = Group
  decorates :group, :event

  # load group before authorization
  prepend_before_filter :parent
  
end
