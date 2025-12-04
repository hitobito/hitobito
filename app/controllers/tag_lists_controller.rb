class TagListsController < ListController
  include FilteredPeople

  self.nesting = Group

  skip_authorization_check
  skip_authorize_resource

  helper_method :group

  respond_to :js, only: [:new, :deletable]

  def create
    manageable_people_ids = manageable_people.map(&:id)

    Bulk::TagAddJob.new(manageable_people_ids, tag_names).enqueue!
    count = manageable_people_ids.size

    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def destroy
    manageable_people_ids = manageable_people.map(&:id)

    Bulk::TagRemoveJob.new(manageable_people_ids, tag_names).enqueue!
    count = manageable_people_ids.size

    redirect_to(group_people_path(group), notice: flash_message(:success, count: count))
  end

  def new
    @people_count = manageable_people_ids.count
  end

  def deletable
    @existing_tags = manageable_people.flat_map(&:tags)
      .each_with_object(Hash.new(0)) do |tag, tag_counts|
      tag_counts[tag] += 1
    end
  end

  private

  def flash_message(type, attrs = {})
    I18n.t("#{controller_name}.#{action_name}.#{type}", **attrs)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def manageable_people_ids
    @manageable_people_ids ||= manageable_people.map(&:id)
  end

  def manageable_people
    @manageable_people ||= if params[:ids] == "all"
      params.delete(:ids)
      @manageable_people_ids = %w[all]

      person_filter(PersonFullReadables).entries.includes(:tags).distinct
    else
      # @manageable_people ||= people.select { |person| current_ability.can?(:assign_tags, person) }
      Person.includes(:tags)
        .where(id: list_param(:ids))
        .distinct
        .select { |person| current_ability.can?(:assign_tags, person) }
    end
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
