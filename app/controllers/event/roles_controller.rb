class Event::RolesController < CrudController
  require_relative '../../decorators/event/role_decorator'

  self.nesting = Group, Event

  decorates :event_role, :event, :group

  # load group before authorization
  prepend_before_filter :parent, :group

  hide_action :index, :show


  def create
    assign_attributes
    new_participation = entry.participation.new_record?
    created = with_callbacks(:create, :save) { save_entry }
    url = new_participation && created ?
      edit_group_event_participation_path(group, event, entry.participation) :
      group_event_participations_path(group, event)
    respond_with(entry, success: created, location: url)
  end

  def update
    super(location: group_event_participation_path(group, event, entry.participation_id))
  end

  def destroy
    super(location: group_event_participations_path(group, event))
  end

  private

  def build_entry
    role = parent.class.find_role_type!(model_params && model_params.delete(:type)).new

    # delete unused attributes
    model_params.delete(:event_id)
    model_params.delete(:person)

    role.participation = parent.participations.where(:person_id => model_params.delete(:person_id)).first_or_initialize
    role.participation.init_answers if role.participation.new_record?

    role
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    "Rolle #{Event::RoleDecorator.decorate(entry).flash_info}".html_safe
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
