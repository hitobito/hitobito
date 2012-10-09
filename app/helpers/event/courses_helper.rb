# encoding: UTF-8
module Event::CoursesHelper

  def group_link_list
    year_param = { year: @year }
    all_groups = link_to("Alle Gruppen", event_courses_path(year_param))
    can_offer_courses.map do |group|
      link = event_courses_path(year_param.merge(group: group.id))
      link_to(group.name, link)
    end.unshift(all_groups)
  end

  def courses_by_kinds
    by_kind = entries.group_by { |entry| entry.kind.label }
    by_kind.each {|kind, entries| entries.sort_by! {|e| e.dates.first.try(:start_at) } }
    by_kind
  end

  def can_offer_courses
    @offered_courses ||= Group.can_offer_courses 
  end

  def group_title
    group_id && group_id > 0  ? Group.find(group_id).name : "Alle Gruppen"
  end

  def group_param
    group_id && group_id > 0 ? { group: group_id }  : {}
  end

  def page_title
    return "Verfügbare Kurse" unless can?(:manage_courses, current_user)
    title = group_id > 0 ? group_title : "allen Gruppen"
    "Verfügbare Kurse in #{title}"
  end

end
