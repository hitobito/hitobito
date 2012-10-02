Fabricator(:event_question, class_name: 'Event::Question') do
  event
  question { Faker::Lorem.words.join(' ') + '?' }
end
