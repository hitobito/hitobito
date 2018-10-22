class RoleListsController < CrudController
  self.nesting = Group

  self.permitted_attrs = [:type, :group_id, :label]

  skip_authorization_check
  skip_authorize_resource

  rescue_from CanCan::AccessDenied, with: :handle_access_denied

  before_action :validate_role_type, only: [:create, :update]

  helper_method :group

  def create
    new_roles = build_new_roles_hash
    count = Role.create(new_roles).count
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def destroy
    count = Role.destroy(deletable_role_ids).count
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def update
    count = Role.transaction do
      Role.destroy(deletable_role_ids)
      Role.create(build_moving_roles_hash).count
    end

    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def new
    respond_to do |format|
      format.js do
        @group_selection = group.groups_in_same_layer.to_a
        @people_ids = params[:ids]
        @people_count = people.count
      end
    end
  end

  def move
    respond_to do |format|
      format.js do
        @group_selection = group.groups_in_same_layer.to_a
        @people_ids = params[:ids]
      end
    end
  end

  def movable
    respond_to do |format|
      format.js do
        @new_group_id = model_params[:group_id]
        @new_role_type = model_params[:type]
        @role_types = collect_available_role_types
        @people_ids = params[:ids]
      end
    end
  end

  def deletable
    respond_to do |format|
      format.js do
        @role_types = collect_available_role_types
        @people_ids = params[:ids]
      end
    end
  end

  def entry
    super.decorate
  end

  def self.model_class
    Role
  end

  private

  def collect_available_role_types
    roles.each_with_object({}) do |role, hash|
      next unless can?(:destroy, role)
      key = role.group.name
      hash[key] = {} if hash[key].blank?

      type = role.type
      count = hash[key][type].blank? ? 1 : hash[key][type] + 1
      hash[key][type] = count
    end
  end

  def validate_role_type
    if role_type.blank? || !Object.const_defined?(role_type.camelize)
      redirect_to(group_people_path(group), alert: flash_message(:failure))
    end
  end

  def build_new_roles_hash
    people.map do |person|
      role = build_role(person.id)
      authorize!(:create, role, message: access_denied_flash(person))
      role.attributes
    end
  end

  def build_moving_roles_hash
    people.map do |person|
      new_role = build_role(person.id)
      authorize!(:create, new_role, message: access_denied_flash(person))
      new_role.attributes
    end
  end

  def build_role(person_id)
    role = build_role_type
    role.attributes = permitted_params(@type)
    role.person_id = person_id
    role
  end

  def build_role_type
    @type = new_group.class.find_role_type!(role_type)
    @type.new
  end

  def deletable_role_ids
    roles.where(type: role_types.keys).map do |r|
      authorize!(:destroy, r, message: access_denied_flash(r.person)).id
    end
  end

  def permitted_params(role_type = entry.class)
    model_params.permit(role_type.used_attributes + permitted_attrs)
  end

  def handle_access_denied(e)
    redirect_to(group_people_path(group), alert: e.message)
  end

  def access_denied_flash(person)
    I18n.t("#{controller_name}.access_denied", person: person.full_name)
  end

  def flash_message(type, attrs = {})
    I18n.t("#{controller_name}.#{action_name}.#{type}", attrs)
  end

  def role_type
    model_params[:type]
  end

  def role_types
    model_params && model_params[:types] ? model_params[:types] : {}
  end

  def new_group
    @new_group ||= Group.find(model_params[:group_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def people
    @people ||= Person.where(id: people_ids).uniq
  end

  def people_ids
    params[:ids].to_s.split(',')
  end

  def roles
    group_ids = params[:range] == ('layer' || 'deep') ? layer_group_ids : group
    @roles ||= Role.where(person_id: people_ids, group_id: group_ids)
  end

  def layer_group_ids
    group.groups_in_same_layer.pluck(:id)
  end

  def person_filter
    @person_filter ||= Person::Filter::List.new(@group, current_user, list_filter_args)
  end
end
