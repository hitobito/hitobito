class EventsController < CrudController

  self.nesting = Group
  
  decorates :event

  # load group before authorization
  prepend_before_filter :parent

  def new
    assign_attributes
    entry.init_questions
    respond_with(entry)
  end

  private 
  
  def build_entry 
    event = model_params.delete(:type).constantize.new
    event.group_id = model_params.delete(:group_id)
    event
  end

  def assign_attributes
    model_params.delete(:contact)
    super
  end
  
end
