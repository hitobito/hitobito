class Event::RolesController < CrudController
  require_relative '../../decorators/event/role_decorator'
   
  self.nesting = Group, Event
  
  decorates :event_role, :event, :group
    
  # load group before authorization
  prepend_before_filter :parent, :group
  
  hide_action :index, :show
  
  
  def create
    super(location: group_event_participations_path(group, event))
  end
  
  def update
    super(location: group_event_participation_path(group, event, entry.participation_id))
  end
  
  def destroy
    super(location: group_event_participations_path(group, event))
  end
  
  private 
  
  def build_entry 
    if model_params.blank? || !parent.class.role_types.collect(&:sti_name).include?(model_params[:type])
      raise ActiveRecord::RecordNotFound 
    end
    
    # delete unused attributes
    model_params.delete(:event_id)
    model_params.delete(:person)
    
    role = model_params.delete(:type).constantize.new
    
    role.participation = parent.participations.where(:person_id => model_params.delete(:person_id)).first_or_initialize
    role.participation.init_answers if role.participation.new_record?

    role
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    "#{models_label(false)} #{Event::RoleDecorator.decorate(entry).flash_info}".html_safe
  end
  
  def event
    parent
  end
  
  def group
    @group ||= parents.first
  end
 
  def parent_scope
    model_class
  end
  
  class << self
    def model_class
      Event::Role
    end
  end
  
end
