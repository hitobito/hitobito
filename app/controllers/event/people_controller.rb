class Event::PeopleController < CrudController
  
  self.nesting = Event
  
  decorates :event, :people, :person
  
  before_filter :set_group
  
  
  def authorize!(*args)
    super(:index_people, parent)
  end
  
  private
  
  def list_entries(action = :index)
    parent.people.
           preload_public_accounts.
           includes(:event_participations).
           order_by_participation(parent.class).
           order_by_name
  end
  
  def set_group
    @group = parent.group
  end
  
  class << self
    def model_class
      Person
    end
  end
  
end