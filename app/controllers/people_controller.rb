# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeopleController < CrudController

  include Concerns::RenderPeopleExports
  include Concerns::AsyncDownload

  self.nesting = Group

  self.remember_params += [:name, :range, :filters, :filter_id]

  self.permitted_attrs = [:first_name, :last_name, :company_name, :nickname, :company,
                          :gender, :birthday, :additional_information,
                          :picture, :remove_picture] +
                          Contactable::ACCESSIBLE_ATTRS +
                          [household_people_ids: []] +
                          [relations_to_tails_attributes: [:id, :tail_id, :kind, :_destroy]]



  # required to allow api calls
  protect_from_forgery with: :null_session, only: [:index, :show]


  decorates :group, :person, :people, :add_requests

  helper_method :index_full_ability?

  # load group before authorization
  prepend_before_action :parent

  prepend_before_action :entry, only: [:show, :edit, :update, :destroy,
                                       :send_password_instructions, :primary_group]

  before_save :validate_household
  after_save :persist_household

  before_render_show :load_person_add_requests, if: -> { html_request? }
  before_render_show :load_grouped_person_tags, if: -> { html_request? }
  before_render_index :load_people_add_requests, if: -> { html_request? }

  def index # rubocop:disable Metrics/AbcSize we support a lot of format, hence many code-branches
    respond_to do |format|
      format.html  { @people = prepare_entries(filter_entries).page(params[:page]) }
      format.pdf   { render_pdf(filter_entries, group) }
      format.csv   { render_tabular_entries_in_background(:csv)  && redirect_to(action: :index) }
      format.xlsx  { render_tabular_entries_in_background(:xlsx) && redirect_to(action: :index) }
      format.vcf   { render_vcf(filter_entries.includes(:phone_numbers)) }
      format.email { render_emails(filter_entries) }
      format.json  { render_entries_json(filter_entries) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.pdf  { render_pdf([entry], group) }
      format.csv  { render_tabular_entry(:csv) }
      format.xlsx { render_tabular_entry(:xlsx) }
      format.vcf  { render_vcf([entry]) }
      format.json { render_entry_json }
    end
  end

  # POST button, send password instructions
  def send_password_instructions
    Person::SendLoginJob.new(entry, current_user).enqueue!
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
    success = entry.update(primary_group_id: params[:primary_group_id])
    respond_to do |format|
      format.html { redirect_to group_person_path(group, entry) }
      format.js do
        return render :primary_group if success
        flash.now.alert = I18n.t('global.errors.header', count: entry.errors.size)
        render 'shared/update_flash'
      end
    end
  end

  private_class_method

  # dont use class level accessor as expression is evaluated whenever constant is
  # loaded which might be before wagon that defines groups / roles has been loaded
  def self.sort_mappings_with_indifferent_access
    { roles: [Person.order_by_role_statement].
      concat(Person.order_by_name_statement) }.with_indifferent_access
  end

  private

  alias group parent

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

  def load_people_add_requests
    if params[:range].blank? && can?(:create, @group.roles.new)
      @person_add_requests = @group.person_add_requests.list.includes(person: :primary_group)
    end
  end

  def load_person_add_requests
    if can?(:update, entry)
      @add_requests = entry.add_requests.includes(:body, requester: { roles: :group })
      set_add_request_status_notification if show_add_request_status?
    end
  end

  def load_grouped_person_tags
    @tags = entry.tags.grouped_by_category
  end

  def show_add_request_status?
    flash[:notice].blank? && flash[:alert].blank? &&
    params[:body_type].present? && params[:body_id].present?
  end

  def set_add_request_status_notification
    status = Person::AddRequest::Status.for(entry.id, params[:body_type], params[:body_id])
    return if status.pending?

    if status.created?
      flash.now[:notice] = status.approved_message
    else
      flash.now[:alert] = status.rejected_message
    end
  end

  def filter_entries
    entries = person_filter.entries
    entries = entries.reorder(sort_expression) if sorting?
    entries
  end

  def list_filter_args
    if params[:filter_id]
      PeopleFilter.for_group(group).find(params[:filter_id]).to_params
    else
      params
    end
  end

  def prepare_entries(entries)
    if index_full_ability?
      entries.includes(:additional_emails, :phone_numbers)
    else
      entries.preload_public_accounts
    end
  end

  def render_tabular_entries_in_background(format)
    full = params[:details].present? && index_full_ability?
    with_async_download_cookie(format, :people_export) do |filename|
      render_tabular_in_background(format, full, filename)
    end
  end

  def prepare_tabular_entries(entries, full)
    if full
      entries
        .select('people.*')
        .preload_accounts
        .includes(relations_to_tails: :tail, qualifications: { qualification_kind: :translations })
        .includes(:primary_group)
    else
      entries.preload_public_accounts.includes(:primary_group)
    end
  end

  def render_tabular_entry(format)
    render_tabular(format, [entry], params[:details].present? && can?(:show_full, entry))
  end

  def render_tabular_in_background(format, full, filename)
    Export::PeopleExportJob.new(
      format, current_person.id, person_filter,
      params.slice(:household).merge(full: full, filename: filename)
    ).enqueue!
  end

  def render_tabular(format, entries, full)
    exporter = Export::Tabular::People::Households if params[:household]
    exporter ||= full ? Export::Tabular::People::PeopleFull : Export::Tabular::People::PeopleAddress
    send_data exporter.export(format, entries), type: format
  end

  def render_entries_json(entries)
    render json: ListSerializer.new(prepare_entries(entries).
                                      includes(:social_accounts).
                                      decorate,
                                    group: @group,
                                    multiple_groups: @person_filter.multiple_groups,
                                    serializer: PeopleSerializer,
                                    controller: self)
  end

  def render_entry_json
    render json: PersonSerializer.new(entry.decorate, group: @group, controller: self)
  end

  def index_full_ability?
    if params[:range].blank? || params[:range] == 'group'
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

  def validate_household
    household.valid?
  end

  def persist_household
    household.persist!
  end

  def household
    @household ||= Person::Household.new(entry, current_ability, nil, current_user)
  end

  def person_filter
    @person_filter ||= Person::Filter::List.new(@group, current_user, list_filter_args)
  end

end
