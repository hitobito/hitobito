class RoleListsController < CrudController
  self.nesting = Group

  self.permitted_attrs = [:type, :group_id] + Role.used_attributes

  skip_authorization_check
  skip_authorize_resource

  rescue_from CanCan::AccessDenied, with: :handle_access_denied

  before_action :validate_role_type, only: [:create, :update]

  helper_method :group

  respond_to :js, only: [:new, :move, :movable, :deletable]

  def create
    new_roles = role_list.build_new_roles_hash
    count = Role.create(new_roles).count
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def destroy
    count = Role.destroy(role_list.deletable_role_ids).count
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def update
    count = Role.transaction do
      Role.destroy(role_list.deletable_role_ids)
      Role.create(role_list.build_new_roles_hash).count
    end

    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def new
    @group_selection = group.groups_in_same_layer.to_a
    @people_ids = params[:ids]
    @people_count = people.count
  end

  def move
    entry # initialize entry so form extensions work without modifications

    @group_selection = group.groups_in_same_layer.to_a
    @people_ids = params[:ids]
  end

  def movable
    assign_attributes
    @role_types = role_list.collect_available_role_types
    @people_ids = params[:ids]
  end

  def deletable
    @role_types = role_list.collect_available_role_types
    @people_ids = params[:ids]
  end

  def self.model_class
    Role
  end

  private

  def entry
    super.decorate
  end

  def validate_role_type
    if role_type.blank? || !Object.const_defined?(role_type.camelize)
      redirect_to(group_people_path(group), alert: flash_message(:failure))
    end
  end

  def handle_access_denied(e)
    redirect_to(group_people_path(group), alert: e.message)
  end

  def flash_message(type, attrs = {})
    I18n.t("#{controller_name}.#{action_name}.#{type}", attrs)
  end

  def role_type
    model_params[:type]
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

  def person_filter
    @person_filter ||= Person::Filter::List.new(@group, current_user, list_filter_args)
  end

  def role_list
    @role_list ||= Role::List.new(current_ability, params)
  end
end
