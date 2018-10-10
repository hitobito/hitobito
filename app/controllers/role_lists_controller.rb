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
    deletable_roles = roles.where(type: role_type).map do |r|
      authorize!(:destroy, r, message: access_denied_flash(r.person))
    end

    count = Role.delete(deletable_roles)
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def update
    moving_roles = roles.where(type: params[:moving_role_type])

    count = Role.transaction do
      Role.create(build_moving_roles_hash(moving_roles))
      moving_roles.destroy_all.count
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
        @moving_role_type = role_type
        @moving_roles_count = roles.where(type: role_type).count
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

  def build_moving_roles_hash(moving_roles)
    moving_roles.map do |role|
      new_role = build_role(role.person_id)
      authorize!(:destroy, role, message: access_denied_flash(role.person))
      authorize!(:create, new_role, message: access_denied_flash(role.person))
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

  def new_group
    @new_group ||= Group.find(model_params[:group_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def people
    @people ||= group.people.where(id: people_ids).uniq
  end

  def people_ids
    params[:ids].to_s.split(',')
  end

  def roles
    @roles ||= group.roles.where(person_id: people_ids)
  end
end
