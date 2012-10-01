
Fabricator(:event_participation, class_name: 'Event::Participation') do
  person
end

types = Event.participation_types + [Event::Course::Participation::Participant]
types.collect {|t| t.name.to_sym }.each do |t|
  Fabricator(t, from: :event_participation, class_name: t)
end
