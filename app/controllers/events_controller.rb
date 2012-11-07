class EventsController < CrudController
  include YearBasedPaging

  self.nesting = Group
  
  decorates :event, :events, :group

  # load group before authorization
  prepend_before_filter :parent

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
    event.group = parent
    event
  end

  def assign_attributes
    model_params.delete(:contact)
    super
  end
  
end
