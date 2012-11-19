class Event::ListsController < ApplicationController
  include YearBasedPaging
  
  attr_reader :group_id
  helper_method :group_id

  skip_authorize_resource only: [:events, :courses]
  decorates :events, :courses
  layout 'events_list'

  def events
    authorize!(:index, Event)
    group_ids = current_user.groups_hierarchy_ids
      
    @events = Event.upcoming.only_group_id(group_ids)
                  .includes(:dates, :groups)
                  .where('events.type != "Event::Course" or events.type is null')
                  .order('event_dates.finish_at ASC')
  end

  def courses
    authorize!(:index, Event::Course)
    set_group_vars
    scope = Event::Course.order('event_kinds.id').in_year(year).list
    @courses = limit_scope_for_user(scope)
  end

  private
  def set_group_vars
    if can?(:manage_courses, current_user)
      # assign default group on initial request
      unless params[:year].present? 
        params[:group] = (Event::Course.groups_with_courses_in_hierarchy(current_user) - [Group.root.id]).first
      end 
      @group_id = params[:group].to_i 
    end

  end

  def limit_scope_for_user(scope)
    if can?(:manage_courses, current_user)
      group_id > 0 ? scope.only_group_id(group_id) : scope
    else
      scope.in_hierarchy(current_user)
    end
  end

end
