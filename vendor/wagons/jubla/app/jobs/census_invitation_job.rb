class CensusInvitationJob < BaseJob
  
  RECIPIENT_ROLES = [Group::StateAgency::Leader,
                     Group::Flock::Leader,
                     Group::ChildGroup::Leader]
    
  def initialize(census)
    @census_id = census.id
  end
  
  def perform
    CensusMailer.invitation(census, recipients).deliver
  end
  
  def recipients
    Person.joins(:roles).
           where(roles: {type: RECIPIENT_ROLES.collect(&:sti_name)}).
           uniq.
           pluck(:email).
           compact
  end
  
  def census
    Census.find(@census_id)
  end
  
end