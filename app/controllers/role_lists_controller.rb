class RoleListsController < CrudController
  include FilteredPeople # provides all_filtered_or_listed_people, person_filter, list_filter_args

  self.nesting = Group

  self.permitted_attrs = [:type, :group_id] + Role.used_attributes

  skip_authorization_check
  skip_authorize_resource

  rescue_from CanCan::AccessDenied, with: :handle_access_denied

  before_action :set_group_selection, only: [:new, :move]
  before_action :validate_role_type, only: [:create, :update]

  helper_method :group

  respond_to :js, only: [:new, :move, :movable, :deletable]

  def create
    role_list.create
    redirect_to_group_people_path(**role_list.counts)
  end

  def destroy
    role_list.destroy
    redirect_to_group_people_path(**role_list.counts)
  end

  def update
    role_list.move
    redirect_to_group_people_path(**role_list.counts)
  end

  def redirect_to_group_people_path(success:, failure:)
    redirect_to(
      group_people_path(group),
      notice: (flash_message(:success, count: success) if success.positive?),
      alert: (flash_message(:failure, count: failure) if failure.positive?)
    )
  end

  def new
    @people_ids ||= params[:ids]
    @people_count = people.count
  end

  def move
    entry # initialize entry so form extensions work without modifications
    @people_ids ||= params[:ids]
  end

  def movable
    assign_attributes
    @role_types = role_list.collect_available_role_types
    @people_ids ||= params[:ids]
  end

  def deletable
    @role_types = role_list.collect_available_role_types
    @people_ids ||= params[:ids]
  end

  def self.model_class
    Role
  end

  private

  def set_group_selection
    @group_selection = group.groups_in_same_layer.to_a
  end

  def entry
    super.decorate
  end

  def validate_role_type
    if role_type.blank? || !Object.const_defined?(role_type.camelize)
      redirect_to(group_people_path(group), alert: flash_message(:failure, count: 0))
    end
  end

  def handle_access_denied(e)
    redirect_to(group_people_path(group), alert: e.message)
  end

  def flash_message(type, attrs = {})
    I18n.t("#{controller_name}.#{action_name}.#{type}", **attrs)
  end

  def role_type
    model_params[:type]
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def people
    @people ||= all_filtered_or_listed_people
  end

  def role_list
    @role_list ||= begin
      role_list_params = params.dup
      role_list_params[:ids] = all_filtered_or_listed_people.unscope(:order).pluck(:id).join(",")

      Role::List.new(current_ability, role_list_params)
    end
  end
end
