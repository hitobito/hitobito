class PeopleController < CrudController

  include RenderPeoplePdf

  self.nesting = Group
  self.nesting_optional = true
  
  self.remember_params += [:name, :kind, :role_types]

  decorates :group, :person, :people
  
  # load group before authorization
  prepend_before_filter :parent

  prepend_before_filter :entry, only: [:show, :new, :create, :edit, :update, :destroy, 
                                       :send_password_instructions]
  
  before_render_show :load_asides
  
  def index
    @people = filter_entries
    respond_to do |format|
      format.html { @people = @people.page(params[:page]) }
      format.pdf  { render_pdf(@people) }
      format.csv  { render_csv(@people) }
    end
  end
  
  # GET ajax, without @group
  def query
    people = []
    if params.has_key?(:q) && params[:q].size >= 3
      people = Person.where(search_condition(:first_name, :last_name, :company_name, :nickname, :town)).
                       only_public_data.
                       order_by_name.
                       limit(10)
      people = decorate(people)
    end
    
    render json: people.collect(&:as_typeahead)
  end
  
  def show
    if parent.nil?
      flash.keep
      redirect_to person_home_path(entry)
    else
      respond_to do |format|
        format.html { entry }
        format.pdf  { render_pdf([entry]) }
        format.csv  { render_csv([entry]) }
      end
    end
  end

  def history
    @roles = entry.all_roles

    @participations_by_event_type = entry.event_participations.
                                            active.
                                            includes(:roles, event: [:dates, :groups]).
                                            uniq.
                                            order('event_dates.start_at DESC').
                                            group_by do |p| 
                                              p.event.class.label_plural
                                            end

    @participations_by_event_type.each do |kind, entries| 
      entries.collect! {|e| Event::ParticipationDecorator.new(e) }
    end

  end
  
  # POST button, send password instructions
  def send_password_instructions
    SendLoginJob.new(entry, current_user).enqueue!
    flash.now[:notice] = I18n.t("#{controller_name}.#{action_name}")
    render 'shared/update_flash'
  end

  private
  
  def render_csv(people)
    csv = params[:details] && can?(:index_full_people, @group) ?
      Export::CsvPeople.export_full(people) :
      Export::CsvPeople.export_address(people)
    send_data csv, type: :csv
  end
  
  def filter_entries
    if params[:role_types]
      list_entries(params[:kind]).where(roles: {type: params[:role_types]})
    else
      list_entries.affiliate(false)
    end
  end
  
  def list_entries(kind = nil)
    list_scope(kind).
          preload_public_accounts.
          preload_groups.
          uniq.
          order_by_name
  end
  
  def list_scope(kind = nil)
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
    person.roles << create_role
    person
  end
  
  def create_role
    type = params[:role] && params[:role][:type]
    role = parent.class.find_role_type!(type).new
    role.group_id = params[:role][:group_id]
    authorize! :create, role
    
    role
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
