class Event::CoursesController < EventsController
  self.nesting_optional = true
  helper_method :courses_by_kinds, :can_offer_courses, :group_id,
    :current_year, :group_name, :year
  attr_reader :year

  decorates :events

  class << self
    def model_class
      Event::Course
    end
  end

  private
  def list_entries
    @year = params[:year].to_i > 0 ? params[:year].to_i : current_year 
    @years = (@year-3...@year+3)
    scoped = super.includes(:group, :kind, :dates)
    scoped = scoped.in_year(@year)
    group_id > 0 ? scoped.for_group(group_id) : scoped.in_year(@year)
  end

  def courses_by_kinds
    entries.group_by { |entry| entry.kind.label }
  end

  def can_offer_courses
    Group.can_offer_courses
  end

  def group_id
    params[:group].to_i
  end

  def group_name
    Group.find(group_id).name
  end

  def current_year
    Date.today.year
  end

end
