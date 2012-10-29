class Event::CoursesController < EventsController
  self.nesting_optional = true
  attr_reader :group_id
  helper_method :group_id
  decorates :events

  class << self
    def model_class
      Event::Course
    end
  end

  private
  
  def list_entries
    set_year_vars
    set_group_vars
    scoped = model_scope.order('event_kinds.id').in_year(@year).list
    limit_scope_for_user(scoped)
  end


  def set_group_vars
    if can?(:manage_courses, current_user)
      # assign default group on initial request
      unless params[:year].present? 
        params[:group] = (Event::Course.groups_with_courses_in_hierarchy(current_user) - [Group.root.id]).first
      end 
      @group_id = params[:group].to_i 
    end

  end

  def limit_scope_for_user(scoped)
    if can?(:manage_courses, current_user)
      group_id > 0 ? scoped.only_group_id(group_id) : scoped
    else
      scoped.in_hierarchy(current_user)
    end
  end

end
