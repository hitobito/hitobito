ch = Group.roots.first
coach_course = Event::Kind.where(label: 'Coachkurs').first
group_ids = Group.where(type: [Group::State, Group::Federation].map(&:to_s)).pluck(:id)

course_data = group_ids.map do |group_id|
  { group_id: group_id,
    name: coach_course.label,
    kind_id: coach_course.id }
end
course_data = course_data.map do |course| 
  past = rand(50).days.ago
  present = rand(10).day.ago
  future = rand(50).days.from_now
  labels = %w(past present future)
  [past, present, future].each_with_index.map do |date,index| 
    closing = date + (rand(30) + 10).days
    name = "#{coach_course.label} #{labels[index]}"
    course.merge(application_opening_at: date, application_closing_at: closing, name: name)
  end
end

Event::Course.seed(:application_opening_at, course_data.flatten)
