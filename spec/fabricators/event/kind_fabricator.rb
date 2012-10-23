Fabricator(:event_kind, class_name: 'Event::Kind') do
  label { Faker::Company.bs }
end
