# frozen_string_literal: true

class PeopleFiltersController < CrudController
  self.nesting = Group

  CRITERIAS_KEY = :people_filter_active_criterias
  CRITERIAS = %w[role attributes tag qualification]

  decorates :group

  skip_authorize_resource only: [:create]

  # load group before authorization
  prepend_before_action :parent

  before_render_form :compose_role_lists, :possible_tags

  helper_method :people_list_path, :criterias, :criterion, :criterion_id

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

    respond_to do |format|
      if request.method == "GET"
        track(criterion)
        format.turbo_stream { render "create", status: :ok }
      end
      if request.method == "POST"
        clear(criterion)
        format.turbo_stream { render "delete" }
      end
    end
  end

  def criterion = params[:criterion]

  def criterias = flash[CRITERIAS_KEY]

  def criterion_id = "#{criterion}-configuration"

  private

  def track(criterion) = flash[CRITERIAS_KEY] = criterias.to_a + [criterion]

  def clear(criterion) = flash[CRITERIAS_KEY] = criterias.to_a - [criterion]

  alias_method :group, :parent

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

  def role_types
    Role::TypeList.new(group.class).role_types.each_with_object([]) do |(key, subhash), result|
      subhash.each do |subkey, role_list|
        role_list.each do |role_type|
          label = (subkey == key) ? "#{key} -> #{role_type.label}" : "#{key} -> #{subkey} -> #{role_type.label}"
          result << [label, role_type.id, role_type.id]
        end
      end
    end
  end

  def compose_role_lists
    @qualification_kinds = QualificationKind.list.without_deleted
      .map { |qualification| [qualification.label, qualification.id, qualification.id] }
    @roles = role_types
    @kinds = Person::Filter::Role::KINDS.map { |kind| [t("people_filters.form.filters_role_kind.#{kind}"), kind, kind] }

    @validities = [
      [t("people_filters.qualification.validity_label.active"), "active"],
      [t("people_filters.qualification.validity_label.reactivateable"), "reactivateable"],
      [t("people_filters.qualification.validity_label.not_active_but_reactivateable"), "not_active_but_reactivateable"],
      [t("people_filters.qualification.validity_label.not_active"), "not_active"],
      [t("people_filters.qualification.validity_label.all"), "all"],
      [t("people_filters.qualification.validity_label.none"), "none"],
      [t("people_filters.qualification.validity_label.only_expired"), "only_expired"]
    ]
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
