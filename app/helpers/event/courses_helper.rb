# encoding: UTF-8
module Event::CoursesHelper

  def group_link_list(groups)
    year_param = { year: @year || current_year }
    all_groups = link_to("Alle Gruppen", event_courses_path(year_param))
    groups.map do |group|
      link = event_courses_path(year_param.merge(group: group.id))
      link_to(group.name, link)
    end.unshift(all_groups)
  end

  def group_title
    group_id > 0  ? group_name : "Alle Gruppen"
  end

  def group_param
    group_id > 0 ? { group: group_id }  : {}
  end

  def page_title
    title = group_id > 0 ? group_title : "allen Gruppen"
    "Verfügbare Kurse in #{title}"
  end

end
