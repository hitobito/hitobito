# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#

# Hilfsleiter
class Event::Role::AssistantLeader < Event::Role

  self.permissions = [:full, :contact_data]

  self.leader = true

end
