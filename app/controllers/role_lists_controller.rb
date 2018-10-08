class RoleListsController < CrudController
  self.nesting = Group

  self.permitted_attrs = [:type, :group_id, :label]

  skip_authorize_resource
  skip_authorization_check only: :move
  before_action :authorize, except: :move
  before_action :validate_role_type, only: [:create, :update]

  helper_method :group

  def create
    new_roles = people.map do |person|
      parent.roles.build(person_id: person.id,
                         type: role_type)
    end

    count = Role.create(new_roles.map(&:attributes)).count
    redirect_to(group_people_path(parent), notice: flash_message(:success, count: count))
  end

  def destroy
    count = roles.where(type: role_type).destroy_all.count
    redirect_to(group_people_path(parent), notice: flash_message(:success, count: count))
  end

  def move
    @group_selection = group.groups_in_same_layer.to_a
    @moving_people = params[:ids]
    @moving_role_type = role_type
    @moving_roles_count = roles.where(type: role_type).count
  end

  def update
    moving_roles = roles.where(type: params[:moving_role_type])

    count = Role.transaction do
      Role.create(build_roles_hash(moving_roles))
      moving_roles.destroy_all.count
    end

    redirect_to(group_people_path(parent), notice: flash_message(:success, count: count))
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
      redirect_to(group_people_path(parent), alert: flash_message(:failure))
    end
  end

  def build_roles_hash(moving_roles)
    moving_roles.map do |role|
      new_role = build_new_type(role)
      authorize!(:destroy, role)
      authorize!(:create, new_role)
      new_role.attributes
    end
  end

  def build_new_type(role)
    new_role = build_role
    new_role.attributes = permitted_params(@type)
    new_role.person_id = role.person_id
    new_role.group_id = model_params[:group_id]
    new_role
  end

  def build_role
    @type = new_group.class.find_role_type!(role_type)
    @type.new
  end

  def permitted_params(role_type = entry.class)
    model_params.permit(role_type.used_attributes)
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
    @people ||= parent.people.where(id: person_ids).uniq
  end

  def person_ids
    @person_ids ||= params[:ids].to_s.split(',')
  end

  def roles
    @roles ||= parent.roles.where(person_id: person_ids)
  end

  def authorize
    roles.each do |role|
      authorize!(action_name.to_sym, role)
    end
  end
end
