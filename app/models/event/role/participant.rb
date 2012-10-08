# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#

# Teilnehmer
class Event::Role::Participant < Event::Role
  
  self.permissions = [:contact_data]
  
  after_save :update_count
  after_destroy :update_count
  
  
  private
  
  def update_count
    event.refresh_participant_count! if event
  end
  
end
