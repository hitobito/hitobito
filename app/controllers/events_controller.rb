class EventsController < CrudController
  attr_accessor :year_range
  helper_method :year_range

  self.nesting = Group
  
  decorates :event, :events, :group

  # load group before authorization
  prepend_before_filter :parent

  def new
    assign_attributes
    entry.init_questions
    respond_with(entry)
  end

  def list_entries
    set_year_vars
    model_scope.list.in_year(@year)
  end

  private
  
  def set_year_vars
    this_year = Date.today.year
    @year_range = (this_year-2)...(this_year+3)
    @year = year_range.include?(params[:year].to_i) ? params[:year].to_i : this_year 
  end
  
  def build_entry
    type = model_params.delete(:type).presence || 'Event'
    event = type.constantize.new
    event.group_id = model_params.delete(:group_id)
    event
  end

  def assign_attributes
    model_params.delete(:contact)
    super
  end
  
end
