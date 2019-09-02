class TagListsController < ListController
  self.nesting = Group

  skip_authorization_check
  skip_authorize_resource

  helper_method :group

  respond_to :js, only: [:new, :deletable]

  def create
    new_tags = tag_list.build_new_tags
    new_tags[:hash].each do |person, tags|
      person.tag_list.add(tags)
      new_tags[:count] -= tags.count unless person.save
    end
    redirect_to(group_people_path(group), notice: flash_message(:success, count: new_tags[:count]))
  end

  def destroy
    tags = ActsAsTaggableOn::Tagging.where(taggable_type: Person.name,
                                           taggable_id: tag_list.manageable_people_ids,
                                           tag_id: tag_list.tag_ids)
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

  private

  def flash_message(type, attrs = {})
    I18n.t("#{controller_name}.#{action_name}.#{type}", attrs)
  end

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
