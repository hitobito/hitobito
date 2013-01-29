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
    respond_to do |format|
      format.html { @people = filter_entries.preload_public_accounts.page(params[:page]) }
      format.pdf  { render_pdf(filter_entries) }
      format.csv  { render_entries_csv }
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
    if group.nil?
      flash.keep
      redirect_to person_home_path(entry)
    else
      respond_to do |format|
        format.html { entry }
        format.pdf  { render_pdf([entry]) }
        format.csv  { render_entry_csv }
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
  
  alias_method :group, :parent

  def create_role
    type = params[:role] && params[:role][:type]
    role = group.class.find_role_type!(type).new
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

  def find_entry
    if group && group.root?
      # every person may be displayed underneath the root group, 
      # even if it does not directly belong to it.
      Person.find(params[:id])
    else
      super
    end
  end
  
  def build_entry
    person = super
    person.roles << create_role
    person
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
  
  def render_entries_csv
    full = full_csv_export?
    entries = if full
      filter_entries.select('people.*').includes(:phone_numbers, :social_accounts)
    else
      filter_entries.preload_public_accounts
    end
    render_csv(entries, full)
  end
 
  def render_entry_csv
    render_csv([entry], params[:details].present? && can?(:show_full, entry))
  end
  
  def render_csv(entries, full)
    csv = if full
      Export::CsvPeople.export_full(entries)
    else
      Export::CsvPeople.export_address(entries)
    end
    send_data csv, type: :csv
  end
    
  def full_csv_export?
    if params[:details].present?
      if params[:kind].blank?
        can?(:index_full_people, @group)
      else
        can?(:index_deep_full_people, @group)
      end
    end
  end
  
  def authorize_class
    authorize!(:index_people, group)
  end
end
