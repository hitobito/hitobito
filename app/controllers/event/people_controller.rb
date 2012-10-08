class Event::PeopleController < CrudController
  
  self.nesting = Event
  
  before_filter :set_group
  
  
  
  private
  
  def authorize!(*args)
    super(:index_people, parent)
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