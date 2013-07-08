class Event::ParticipationConfirmationJob < BaseJob

  self.parameters = [:participation_id]

  def initialize(participation)
    @participation_id = participation.id
  end

  def perform
    if participation.person.email.present?
      Event::ParticipationMailer.confirmation(participation).deliver
    end
    if participation.event.requires_approval?
      recipients = approvers
      if recipients.present?
        Event::ParticipationMailer.approval(participation, recipients).deliver
      end
    end
  end

  def approvers
    approver_types = Role.types_with_permission(:approve_applications).collect(&:sti_name)
    layer_ids = participation.person.groups.without_deleted.
                                            merge(Person.affiliate(false)).
                                            collect(&:layer_group_id).
                                            uniq
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
