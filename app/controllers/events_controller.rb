class EventsController < CrudController
  include YearBasedPaging

  self.nesting = Group
  
  decorates :event, :events, :group

  # load group before authorization
  prepend_before_filter :parent
  
  before_render_form :load_sister_groups

  def new
    assign_attributes
    entry.init_questions
    respond_with(entry)
  end

  # list scope preload :groups, :kinds which we dont need
  def list_entries
    model_scope.
      order_by_date.
      preload_all_dates.
      uniq.
      in_year(year)
  end

  private
  
  
  def build_entry
    type = model_params && model_params.delete(:type).presence
    type ||= 'Event'
    event = type.constantize.new
    event.groups << parent
    event
  end

  def assign_attributes
    model_params.delete(:contact)
    super
  end
  
  def group
    parent
  end
  
  def load_sister_groups
    master = @event.groups.first
    @groups = master.parent_id? ? 
                master.parent.children.
                              where(type: master.type).
                              where('groups.id <> ?', group.id).
                              order(:name) :
                []
  end
  
end
