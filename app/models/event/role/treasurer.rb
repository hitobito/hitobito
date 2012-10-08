# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#

# Kassier
class Event::Role::Treasurer < Event::Role
  
  self.permissions = [:contact_data]
end
