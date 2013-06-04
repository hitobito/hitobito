class Event::ListsController < ApplicationController
  include YearBasedPaging

  attr_reader :group_id
  helper_method :group_id

  skip_authorize_resource only: [:events, :courses]


  def events
    authorize!(:index, Event)

    events = Event.upcoming.
                   in_hierarchy(current_user).
                   includes(:dates, :groups).
                   where('events.type != ? OR events.type IS NULL', Event::Course.sti_name).
                   order('event_dates.start_at ASC')

    @events_by_month = EventDecorator.decorate(events).group_by do |entry|
      if entry.dates.present?
        l(entry.dates.first.start_at, format: :month_year)
      else
        "Ohne Datumsangabe"
      end
    end
  end

  def courses
    authorize!(:index, Event::Course)
    set_group_vars
    scope = Event::Course.order('event_kinds.label').in_year(year).list
    courses = EventDecorator.decorate(limit_scope_for_user(scope))
    @courses_by_kind = courses.group_by { |entry| entry.kind.label }
    @courses_by_kind.each do |kind, entries|
      entries.sort_by! {|e| e.dates.first.try(:start_at) || Time.zone.now }.
              collect! {|e| EventDecorator.new(e) }
    end
  end

  private

  def set_group_vars
    if can?(:manage_courses, Event)
      # assign default group on initial request
      unless params[:year].present?
        params[:group_id] = Group.course_offerers.
                                  where(id: current_user.groups_hierarchy_ids).
                                  where("groups.id <> ?", Group.root.id).
                                  select(:id).
                                  first.
                                  try(:id)
      end
      @group_id = params[:group_id].to_i
    end

  end

  def limit_scope_for_user(scope)
    if can?(:manage_courses, Event)
      group_id > 0 ? scope.with_group_id(group_id) : scope
    else
      scope.in_hierarchy(current_user)
    end
  end

end
