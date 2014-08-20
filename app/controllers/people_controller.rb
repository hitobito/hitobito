# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeopleController < CrudController

  include Concerns::RenderPeopleExports

  self.nesting = Group
  self.nesting_optional = true

  self.remember_params += [:name, :kind, :role_type_ids]

  self.permitted_attrs = [:first_name, :last_name, :company_name, :nickname, :company,
                          :gender, :birthday, :additional_information,
                          :picture, :remove_picture] +
                          Contactable::ACCESSIBLE_ATTRS +
                          [relations_to_tails_attributes: [:id, :tail_id, :kind, :_destroy]]

  self.sort_mappings = { roles: [Person.order_by_role_statement].
                                  concat(Person.order_by_name_statement) }

  decorates :group, :person, :people, :versions

  helper_method :index_full_ability?

  # load group before authorization
  prepend_before_action :parent

  prepend_before_action :entry, only: [:show, :edit, :update, :destroy,
                                       :send_password_instructions, :primary_group]

  before_render_show :load_asides, if: -> { request.format.html? }

  def index
    filter = Person::ListFilter.new(@group, current_user, params[:kind], params[:role_type_ids])
    entries = filter.filter_entries
    entries = entries.reorder(sort_expression) if sorting?
    @multiple_groups = filter.multiple_groups

    respond_to do |format|
      format.html  { @people = prepare_entries(entries).page(params[:page]) }
      format.pdf   { render_pdf(entries) }
      format.csv   { render_entries_csv(entries) }
      format.email { render_emails(entries) }
      format.json  { render_entries_json(entries) }
    end
  end

  def show
    if group.nil?
      flash.keep if request.format.html?
      redirect_to person_home_path(entry, format: request.format.to_sym)
    else
      respond_to do |format|
        format.html
        format.pdf  { render_pdf([entry]) }
        format.csv  { render_entry_csv }
        format.json { render_entry_json }
      end
    end
  end

  # GET ajax, without @group
  def query
    people = []
    if params.key?(:q) && params[:q].size >= 3
      search_clause = search_condition(:first_name, :last_name, :company_name, :nickname, :town)
      people = Person.where(search_clause).
                      only_public_data.
                      order_by_name.
                      limit(10)
      people = decorate(people)
    end

    render json: people.collect(&:as_typeahead)
  end

  def history
    @roles = entry.all_roles

    @participations_by_event_type = alltime_person_participations.group_by do |p|
      p.event.class.label_plural
    end

    @participations_by_event_type.each do |_kind, entries|
      entries.collect! { |e| Event::ParticipationDecorator.new(e) }
    end
  end

  def log
    @versions = PaperTrail::Version.where(main_id: entry.id, main_type: Person.sti_name).
                                    reorder('created_at DESC, id DESC').
                                    includes(:item).
                                    page(params[:page])
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

  def load_asides
    applications = pending_person_applications
    Event::PreloadAllDates.for(applications.collect(&:event))
    @pending_applications = Event::ApplicationDecorator.decorate_collection(applications)
    @upcoming_events      = EventDecorator.decorate_collection(upcoming_person_events)
    @qualifications       = entry.latest_qualifications_uniq_by_kind
    @relations            = entry.relations_to_tails.list.includes(tail: [:groups, :roles])
  end

  def pending_person_applications
    entry.pending_applications.
          includes(event: [:groups]).
          joins(event: :dates).
          order('event_dates.start_at').uniq
  end

  def upcoming_person_events
    entry.upcoming_events.
          includes(:groups).
          preload_all_dates.
          order_by_date
  end

  def alltime_person_participations
    entry.event_participations.
          active.
          includes(:roles, event: [:dates, :groups]).
          uniq.
          order('event_dates.start_at DESC')
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

  def assign_attributes
    if model_params.present?
      email = model_params.delete(:email)
      entry.email = email if can?(:update_email, entry)
    end
    super
  end

  def prepare_entries(entries)
    if index_full_ability?
      entries.includes(:additional_emails, :phone_numbers)
    else
      entries.preload_public_accounts
    end
  end

  def render_entries_csv(entries)
    full = params[:details].present? && index_full_ability?
    render_csv(prepare_csv_entries(entries, full), full)
  end

  def prepare_csv_entries(entries, full)
    if full
      entries.select('people.*').preload_accounts.includes(relations_to_tails: :tail)
    else
      entries.preload_public_accounts
    end
  end

  def render_entry_csv
    render_csv([entry], params[:details].present? && can?(:show_full, entry))
  end

  def render_csv(entries, full)
    if full
      send_data Export::Csv::People::PeopleFull.export(entries), type: :csv
    else
      send_data Export::Csv::People::PeopleAddress.export(entries), type: :csv
    end
  end

  def render_entries_json(entries)
    render json: ListSerializer.new(prepare_entries(entries).
                                      includes(:social_accounts).
                                      decorate,
                                    group: @group,
                                    multiple_groups: @multiple_groups,
                                    serializer: PeopleSerializer,
                                    controller: self)
  end

  def render_entry_json
    render json: PersonSerializer.new(entry.decorate, group: @group, controller: self)
  end

  def index_full_ability?
    if params[:kind].blank?
      can?(:index_full_people, @group)
    else
      can?(:index_deep_full_people, @group)
    end
  end
  public :index_full_ability? # for serializer
  hide_action :index_full_ability?

  def authorize_class
    authorize!(:index_people, group)
  end
end
