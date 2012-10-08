# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer          not null
#  person_id              :integer          not null
#  additional_information :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  active                 :boolean          default(FALSE), not null
#  application_id         :integer
#


Fabricator(:event_participation, class_name: 'Event::Participation') do
  person
  event
end

