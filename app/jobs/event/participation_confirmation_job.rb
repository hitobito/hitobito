class Event::ParticipationConfirmationJob < BaseJob
  
  attr_reader :participation
  
  def initialize(participation)
    @participation = participation
  end
  
  def perform
    Event::ParticipationMailer.confirmation(participation).deliver
    if participation.event.requires_approval? 
      recipients = approvers.to_a
      Event::ParticipationMailer.approval(participation, recipients).deliver if recipients.present?
    end
  end
  
  def approvers
    approver_types = Role.types_with_permission(:approve_applications).collect(&:sti_name)
    layer_ids = participation.person.groups.collect(&:layer_group_id).uniq
    Person.joins(roles: :group).
           where(roles: {type: approver_types}, 
                         groups: {layer_group_id: layer_ids}).
           uniq.
           pluck('people.email').
           compact
  end
  
end