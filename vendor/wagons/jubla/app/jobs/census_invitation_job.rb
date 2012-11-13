class CensusInvitationJob < BaseJob
  
  RECIPIENT_ROLES = [Group::StateAgency::Leader,
                     Group::Flock::Leader,
                     Group::ChildGroup::Leader]
  
  attr_reader :census
  
  def initialize(census)
    @census = census
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
  
end