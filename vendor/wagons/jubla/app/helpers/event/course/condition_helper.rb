module Event::Course::ConditionHelper
  def format_event_course_condition_content(condition)
    strip_tags(condition.content).to_s.truncate(100)
  end
end
