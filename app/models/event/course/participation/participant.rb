# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer
#  person_id              :integer          not null
#  type                   :string(255)      not null
#  label                  :string(255)
#  additional_information :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

# Kursteilnehmer
module Event::Course::Participation
  class Participant < ::Event::Participation::Participant
  
    self.restricted = true
    
  end
end
