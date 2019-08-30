class TagListsController < CrudController
  self.nesting = Group

  skip_authorization_check
  skip_authorize_resource

  # TODO is this necessary?
  #rescue_from CanCan::AccessDenied, with: :handle_access_denied

  #before_action :validate_tag_type, only: :create

  helper_method :group

  respond_to :js, only: [:new, :deletable]

  def create
    new_tags = tag_list.build_new_tags(logger)
    ActiveRecord::Base.transaction do
      new_tags.each do |hash|
        person, tag = hash
        person.tag_list.add(tag)
      end
      new_tags.keys.uniq.each do |person|
        person.save
      end
    end
    redirect_to(group_people_path(group), notice: flash_message(:success, count: new_tags.count))
  end

  def destroy
    tags = ActsAsTaggableOn::Tagging.where({taggable_type: Person.name,
                                            taggable_id: tag_list.manageable_people_ids,
                                            tag_id: tag_list.tag_ids})
    count = tags.destroy_all.count
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def new
    @people_ids = people_ids
    @people_count = @people_ids.count
    @possible_tags = Person.tags
  end

  def deletable
    @existing_tags = tag_list.existing_tags_with_count
    @people_ids = params[:ids]
  end

  def self.model_class
    Tag
  end

  #def model_identifier
  #  model_class.name.demodulize.pluralize.underscore
  #end

  private

  # TODO is this really necessary? Needed to do this because it was looking for tags in Group instance. Is Group the correct place to nest this controller?
  def entry
    tag_list
  end

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
    @tag_list ||= Tag::List.new(current_ability, params)
  end
end
