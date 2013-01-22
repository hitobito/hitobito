# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#

# Hauptsleiter
class Event::Role::Leader < Event::Role
  
  self.permissions = [:full, :qualify]

  self.leader = true
    
end
