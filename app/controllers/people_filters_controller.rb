# frozen_string_literal: true

class PeopleFiltersController < CrudController
  self.nesting = Group
  attr_accessor :filter_criterion

  decorates :group

  skip_authorize_resource only: [:create]

  before_action :set_filter_criteria, except: [:destroy]

  # load group before authorization
  prepend_before_action :parent

  before_render_form :compose_role_lists, :possible_tags

  helper_method :people_list_path

  def new
    assign_attributes
    super
  end

  def create
    if params[:button] == "save"
      authorize!(:create, entry)
      super
    else
      authorize!(:new, entry)
      assign_attributes
      redirect_to result_path
    end
  end

  def destroy
    super(location: people_list_path)
  end

  def filter_criterion
    compose_role_lists
    possible_tags
    @filter_criterion = params[:filter_criterion]
    if @filter_criteria.include?(@filter_criterion.to_sym)
      respond_to do |format|
        if request.method == "GET"
          format.turbo_stream { render 'create', status: :ok }
        end
        if request.method == "POST"
          format.turbo_stream { render 'delete' }
        end
      end
    end
  end

  private

  alias_method :group, :parent

  def set_filter_criteria
    @filter_criteria = [:tag, :role, :qualification, :attributes]
  end

  def build_entry
    filter = super
    filter.group_id = group.id
    filter
  end

  def return_path
    super || people_list_path(filter_id: entry.id)
  end

  def result_path
    search_params = {}
    if entry.filter_chain.present?
      search_params = {
        name: entry.name,
        range: entry.range || "deep",
        filters: entry.filter_chain.to_params
      }
    end
    people_list_path(search_params)
  end

  def compose_role_lists
    @role_types = Role::TypeList.new(group.class)
    @qualification_kinds = QualificationKind.list.without_deleted
    @roles = Role.all.map {  |role| [role.type, role.type, role.id] }
    @kinds = Person::Filter::Role::KINDS.each_with_index
                                        .map {   |kind, index|
                                          [t("people_filters.form.filters_role_kind.#{kind}"),
                                           t("people_filters.form.filters_role_kind.#{kind}"),
                                           index+1]
                                        }
  end

  def assign_attributes
    entry.name = params[:name] || params.dig(:people_filter, :name)
    entry.range = params[:range]
    entry.filter_chain = params.fetch(:filters, nil)&.except(:host)&.to_unsafe_hash
  end

  def people_list_path(options = {})
    group_people_path(group, options)
  end

  def possible_tags
    @possible_tags ||= PersonTags::Translator.new.possible_tags
  end
end
