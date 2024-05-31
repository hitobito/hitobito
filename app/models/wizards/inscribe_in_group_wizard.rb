module Wizards
  class InscribeInGroupWizard < RegistrationWizardBase
    self.steps << Steps::ConfirmInscription

    def initialize_wizard
      self.role = build_role
    end

    def build_role
      group.self_registration_role_type.constantize.new(
        group: group,
        person: person
      )
    end

    def save!
      ::Person.transaction do
        super
        role.save!
        send_notification_email
      end
    end

    private

    def send_notification_email
      return if group.self_registration_notification_email.blank?

      Groups::SelfRegistrationNotificationMailer
        .self_registration_notification(group.self_registration_notification_email,
                                        @role).deliver_now
    end
  end
end
