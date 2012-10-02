module Event::CoursesHelper
  def link_to_year(year)
    return content_tag(:span, year) if year == @year
    link_to(year, event_courses_path(year: year))
  end
end
