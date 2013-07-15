# == Schema Information
#
# Table name: event_questions
#
#  id               :integer          not null, primary key
#  event_id         :integer
#  question         :string(255)
#  choices          :string(255)
#  multiple_choices :boolean          default(FALSE)
#

Fabricator(:event_question, class_name: 'Event::Question') do
  event
  question { Faker::Lorem.words.join(' ') + '?' }
end
