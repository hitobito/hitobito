Fabricator(:event_application, class_name: 'Event::Application') do
  priority_1    { Fabricate(:course)}
  participation { Fabricate(Event::Course::Participation::Participant.name.to_sym) }
end
