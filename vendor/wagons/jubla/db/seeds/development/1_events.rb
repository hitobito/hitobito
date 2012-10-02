ch = Group.roots.first
coach_course = Event::Kind.where(label: 'Coachkurs').first
group_ids = Group.where(type: [Group::State, Group::Federation].map(&:to_s)).pluck(:id)

course_data = group_ids.map do |group_id|
  { group_id: group_id,
    name: coach_course.label,
    kind_id: coach_course.id }
end
course_data = course_data.map do |course| 
  past = 10.times.map {
    opening = rand(5.years).ago
    closing = opening + rand(30).days
    course.merge(application_opening_at: opening, application_closing_at: closing)
  }
  future = 10.times.map { 
    opening = rand(5.years).from_now
    closing = opening + rand(30).days
    course.merge(application_opening_at: opening, application_closing_at: closing)
  }
  [past, future]
end

Event::Course.seed(:application_opening_at, course_data.flatten)
