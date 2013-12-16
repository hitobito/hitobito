# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeopleController < CrudController

  include RenderPeopleExports

  self.nesting = Group
  self.nesting_optional = true

  self.remember_params += [:name, :kind, :role_type_ids]

  decorates :group, :person, :people

  helper_method :index_full_ability?

  # load group before authorization
  prepend_before_filter :parent

  prepend_before_filter :entry, only: [:show, :new, :create, :edit, :update, :destroy,
                                       :send_password_instructions, :primary_group]

  before_render_show :load_asides

  def index
    filter = Person::ListFilter.new(@group, current_user, params[:kind], params[:role_type_ids])
    entries = filter.filter_entries
    @multiple_groups = filter.multiple_groups

    respond_to do |format|
      format.html { set_entries(entries) }
      format.pdf  { render_pdf(entries) }
      format.csv  { render_entries_csv(entries) }
      format.email { render_emails(entries) }
    end
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

  # GET ajax, without @group
  def query
    people = []
    if params.key?(:q) && params[:q].size >= 3
      people = Person.where(search_condition(:first_name, :last_name, :company_name, :nickname, :town)).
                       only_public_data.
                       order_by_name.
                       limit(10)
      people = decorate(people)
    end

    render json: people.collect(&:as_typeahead)
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
      entries.collect! { |e| Event::ParticipationDecorator.new(e) }
    end

  end

  # POST button, send password instructions
  def send_password_instructions
    SendLoginJob.new(entry, current_user).enqueue!
    notice = I18n.t("#{controller_name}.#{action_name}")
    respond_to do |format|
      format.html { redirect_to group_person_path(group, entry), notice: notice }
      format.js do
        flash.now.notice = notice
        render 'shared/update_flash'
      end
    end
  end

  # PUT button, ajax
  def primary_group
    entry.update_column :primary_group_id, params[:primary_group_id]
    respond_to do |format|
      format.html { redirect_to group_person_path(group, entry) }
      format.js
    end
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

  def assign_attributes
    if model_params.present?
      email = model_params.delete(:email)
      entry.email = email if can?(:update_email, entry)
    end
    super
  end

  def set_entries(entries)
    @people = entries.page(params[:page])
    if index_full_ability?
      @people = @people.includes(:phone_numbers)
    else
      @people = @people.preload_public_accounts
    end
  end

  def render_entries_csv(entries)
    full = params[:details].present? && index_full_ability?
    csv_entries = if full
      entries.select('people.*').includes(:phone_numbers, :social_accounts)
    else
      entries.preload_public_accounts
    end
    render_csv(csv_entries, full)
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

  def index_full_ability?
    if params[:kind].blank?
      can?(:index_full_people, @group)
    else
      can?(:index_deep_full_people, @group)
    end
  end

  def authorize_class
    authorize!(:index_people, group)
  end
end
