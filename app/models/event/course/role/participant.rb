# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#

# Kursteilnehmer
module Event::Course::Role
  class Participant < ::Event::Role::Participant
  
    self.restricted = true
    
  end
end
