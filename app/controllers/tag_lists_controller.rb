class TagListsController < CrudController
  self.nesting = Group

  self.permitted_attrs = [:tag, :group_id]

  skip_authorization_check
  skip_authorize_resource

  # TODO is this necessary?
  #rescue_from CanCan::AccessDenied, with: :handle_access_denied

  #before_action :validate_tag_type, only: :create

  helper_method :group

  respond_to :js, only: [:new, :deletable]

  # TODO
  #def create
  #  new_tags = tag_list.build_new_tags_hash
  #  count = Role.create(new_tags).count
  #  redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  #end

  def destroy
    tags = ActsAsTaggableOn::Tagging.where({taggable_type: Person.name,
                                            taggable_id: tag_list.manageable_people_ids,
                                            tag_id: tag_list.tag_ids})
    count = tags.destroy_all.count
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  #def new
  #  @people_ids = people_ids
  #  @people_count = @people_ids.count
  #end

  def deletable
    @existing_tags = tag_list.existing_tags_with_count
    @people_ids = params[:ids]
  end

  def self.model_class
    ActsAsTaggableOn::Tag
  end

  private

  def entry
    tag_list
  end

  # TODO
  #def validate_tag_type
  #  return
  #  if role_type.blank? || !Object.const_defined?(role_type.camelize)
  #    redirect_to(group_people_path(group), alert: flash_message(:failure))
  #  end
  #end

  #def handle_access_denied(e)
  #  redirect_to(group_people_path(group), alert: e.message)
  #end

  def flash_message(type, attrs = {})
    I18n.t("#{controller_name}.#{action_name}.#{type}", attrs)
  end

  #def role_type
  #  model_params[:type]
  #end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def people_ids
    params[:ids].to_s.split(',')
  end

  def tag_list
    @tag_list ||= TagList.new(current_ability, params)
  end
end
