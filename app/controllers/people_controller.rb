class PeopleController < CrudController

  self.nesting = Group
  self.nesting_optional = true
  
  self.remember_params += [:kind, :role_types]

  decorates :group, :person, :people

  # load group before authorization
  prepend_before_filter :parent

  prepend_before_filter :entry, only: [:show, :new, :create, :edit, :update, :destroy, 
                                       :send_password_instructions]
  
  before_render_show :load_asides
  
  def index
    @people = people_for_group
    respond_with(@people)
  end

  def history
    @roles = entry.all_roles
  end
  
  # GET ajax, without @group
  def query
    @people = []
    if params.has_key?(:q) && params[:q].size >= 3
      @people = Person.where(search_condition(:first_name, :last_name, :company_name, :nickname, :town)).
                       only_public_data.
                       order_by_name.
                       limit(10)
    end
    
    render json: decorate(@people).collect(&:as_typeahead)
  end
  
  def show
    if parent.nil?
      flash.keep
      redirect_to group_person_path(entry.groups.select('groups.id').first, entry)
    else
      super
    end
  end

  # POST button, send password instructions
  def send_password_instructions
    entry.send_reset_password_instructions
    flash.now[:notice] = I18n.t("#{controller_name}.#{action_name}")
    render 'shared/update_flash'
  end

  private
  
  def people_for_group
    if params[:role_types]
      list_entries(params[:kind]).where(roles: {type: params[:role_types]})
    else
      list_entries(params[:kind]).affiliate(false)
    end
  end
  
  def list_entries(kind)
    list_scope(kind).
          preload_public_accounts.
          preload_groups.
          uniq.
          order_by_name
  end
  
  def list_scope(kind)
    case kind
    when 'deep'
      @multiple_groups = true
      accessibles.in_or_below(@group)
    when 'layer'
      @multiple_groups = true
      accessibles.in_layer(@group)
    else
      accessibles(@group).order_by_role
    end
  end
    
  def accessibles(group = nil)
    ability = Ability::Accessibles.new(current_user, group)
    Person.accessible_by(ability)
  end
  
  
  def build_entry
    person = super
    
    role = params[:role][:type].constantize.new
    role.group_id = params[:role][:group_id]
    authorize! :create, role
    
    person.roles << role
    
    person
  end
  
  def load_asides
    applications = entry.pending_applications.
                         includes(event: [:groups]).
                         joins(event: :dates).
                         order('event_dates.start_at').uniq
    Event::PreloadAllDates.for(applications.collect(&:event))
    
    @pending_applications = Event::ApplicationDecorator.decorate(applications)
    @upcoming_events      = EventDecorator.decorate(entry.upcoming_events.
                                                    includes(:groups).
                                                    preload_all_dates.
                                                    order_by_date)
    @qualifications = entry.qualifications.includes(:person, :qualification_kind).order_by_date
  end
  
end
