class TagListsController < ListController
  self.nesting = Group

  skip_authorization_check
  skip_authorize_resource

  before_action :manageable_people_ids, only: [:new, :deletable]
  helper_method :group

  respond_to :js, only: [:new, :deletable]

  def create
    count = Tag::List.new(manageable_people, tags).add
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def destroy
    count = Tag::List.new(manageable_people, tags).remove
    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def new
    @people_count = manageable_people.count
  end

  def deletable
    @existing_tags = manageable_people.flat_map(&:tags)
                                      .group_by { |tag| tag }
                                      .map { |tag, occurrences| [tag, occurrences.count] }
  end

  private

  def flash_message(type, attrs = {})
    I18n.t("#{controller_name}.#{action_name}.#{type}", attrs)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def manageable_people_ids
    @people_ids ||= manageable_people.map(&:id)
  end

  def manageable_people
    @manageable_people ||= people.select { |person| current_ability.can?(:manage_tags, person) }
  end

  def people
    @people ||= Person.includes(:tags).where(id: people_ids).uniq
  end

  def people_ids
    return [] if params[:ids].nil?
    params[:ids].to_s.split(',')
  end

  def tags
    @tags ||= ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_id_list)
  end

  def tag_id_list
    return [] if params[:tags].nil?
    return params[:tags].keys if params[:tags].is_a?(Hash)
    params[:tags].split(',').each(&:strip)
  end
end
