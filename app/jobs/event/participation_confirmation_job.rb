class Event::ParticipationConfirmationJob < BaseJob
  
  def initialize(participation)
    @participation_id = participation.id
  end
  
  def perform
    Event::ParticipationMailer.confirmation(participation).deliver
    if participation.event.requires_approval? 
      Event::ParticipationMailer.approval(participation, approvers).deliver if approvers.present?
    end
  end
  
  def approvers
    approver_types = Role.types_with_permission(:approve_applications).collect(&:sti_name)
    layer_ids = participation.person.groups.without_deleted.collect(&:layer_group_id).uniq
    Person.only_public_data.
           joins(roles: :group).
           where(roles: {type: approver_types, deleted_at: nil}, 
                 groups: {layer_group_id: layer_ids}).
           uniq
  end
  
  def participation
    @participation ||= Event::Participation.find(@participation_id)
  end
  
end
