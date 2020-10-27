class TagListsController < ListController
  self.nesting = Group

  skip_authorization_check
  skip_authorize_resource

  helper_method :group

  respond_to :js, only: [:new, :deletable]

  def create
    count = tag_list.add
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def destroy
    count = tag_list.remove
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def new
    @people_count = manageable_people.count
  end

  def deletable
    @existing_tags = manageable_people.flat_map(&:tags)
                                      .each_with_object(Hash.new(0)) do |tag, tag_counts|
                                        tag_counts[tag] += 1
                                      end
  end

  private

  def flash_message(type, attrs = {})
    I18n.t("#{controller_name}.#{action_name}.#{type}", attrs)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def manageable_people
    @manageable_people ||= people.select { |person| current_ability.can?(:manage_tags, person) }
  end

  def people
    @people ||= Person.includes(:tags).where(id: people_ids).distinct
  end

  def people_ids
    list_param(:ids)
  end

  def tags
    @tags ||= ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_names)
  end

  def tag_names
    return params[:tags].each(&:strip) if params[:tags].is_a?(Array)
    list_param(:tags)
  end

  def tag_list
    @tag_list ||= TagList.new(manageable_people, tags)
  end
end
