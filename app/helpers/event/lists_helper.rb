# encoding: UTF-8
module Event::ListsHelper
  
  def group_link_list
    year_param = { year: @year }
    all_groups = link_to("Alle Gruppen", list_courses_path(year_param))
    Group.course_offerers.map do |group|
      link = list_courses_path(year_param.merge(group_id: group.id))
      link_to(group.name, link)
    end.unshift(all_groups)
  end

  def group_title
    group_id && group_id > 0  ? Group.find(group_id).name : "Alle Gruppen"
  end

  def group_param
    group_id && group_id > 0 ? { group_id: group_id } : {}
  end

end
