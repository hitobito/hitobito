class Event::CoursesController < EventsController
  self.nesting_optional = true
  attr_reader :year, :group_id
  helper_method :year, :group_id
  decorates :events

  class << self
    def model_class
      Event::Course
    end
  end

  private
  def list_entries
    set_year_vars
    scoped = model_scope.includes(:group, :kind, :dates).in_year(year) 
    limit_scope_for_user(scoped)
  end

  def set_year_vars
    @year = params[:year].to_i > 0 ? params[:year].to_i : Date.today.year
    @years = (@year-3...@year+3)
  end

  def limit_scope_for_user(scoped)
    @group_id = params[:group].to_i
    if can?(:manage_courses, current_user)
      group_id > 0 ? scoped.only_group_id(group_id) : scoped
    else
      scoped.only_group_id(groups_with_courses_in_hierarchy)
    end
  end

  def groups_with_courses_in_hierarchy
    Group.can_offer_courses.pluck(:id) & current_user.groups_hierarchy
  end

end
