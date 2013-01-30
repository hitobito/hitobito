class EventsController < CrudController
  include YearBasedPaging

  self.nesting = Group

  self.remember_params += [:year]

  decorates :event, :events, :group

  # load group before authorization
  prepend_before_filter :parent

  before_render_form :load_sister_groups
  before_render_form :load_kinds

  def new
    assign_attributes
    entry.dates.build
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
                              without_deleted.
                              where(type: master.type).
                              where('groups.id <> ?', group.id).
                              reorder(:name) :
                []
    # union to include assigned deleted events
    @groups = (@groups | @event.groups) - [group]
  end

  def load_kinds
    if entry.kind_class
      @kinds = entry.kind_class.without_deleted
      @kinds << entry.kind if entry.kind && entry.kind.deleted?
    end
  end
end
