class TagListsController < ListController
  include FilteredPeople

  self.nesting = Group

  skip_authorization_check
  skip_authorize_resource

  helper_method :group, :people_ids

  respond_to :js, only: [:new, :deletable]

  def create
    Bulk::TagAddJob.new(people_ids, tag_names).enqueue!
    redirect_to_people
  end

  def destroy
    Bulk::TagRemoveJob.new(people_ids, tag_names).enqueue!
    redirect_to_people
  end

  def new
    @people_count = people.count
  end

  def deletable
    counts = ActsAsTaggableOn::Tagging
      .where(taggable_type: Person.name, taggable_id: people.reselect(:id))
      .group(:tag_id)
      .distinct
      .count(:taggable_id)
    tags = ActsAsTaggableOn::Tag.where(id: counts.keys).order(:name).index_by(&:id)
    @existing_tags = tags.each_with_object({}) do |(id, tag), hash|
      hash[tag] = counts[tag.id]
    end
  end

  private

  def redirect_to_people
    redirect_to(group_people_path(group, list_filter_params),
      notice: flash_message(:success, count: people.count))
  end

  def flash_message(type, attrs = {})
    I18n.t("#{controller_name}.#{action_name}.#{type}", **attrs)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def people_ids
    @people_ids ||= people.pluck(:id)
  end

  def people
    @people ||= all_filtered_or_listed_people.unscope(:order)
  end

  def tags
    @tags ||= ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_names)
  end

  def tag_names
    if params[:tags].is_a?(Array)
      params[:tags].each(&:strip)
    else
      list_param(:tags)
    end
  end

  def accessibles_class = PersonWritables
end
