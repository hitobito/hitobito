module Wizards
  class RegisterNewUserWizard < RegistrationWizardBase
    self.steps << Steps::NewUserForm

    def initialize_wizard
      assign_person
      assign_role
    end

    def assign_person
      person ||= Person.new
      person.assign_attributes(
        first_name: step(:new_user_form).first_name,
        last_name: step(:new_user_form).last_name,
        nickname: step(:new_user_form).nickname,
        company_name: step(:new_user_form).company_name,
        company: step(:new_user_form).company,
        email: step(:new_user_form).email,
        privacy_policy_accepted_at: Time.zone.now
      )
    end

    def assign_role
      self.role = group.self_registration_role_type.constantize.new(
        group: group,
        person: person
      )
    end

    def save!
      ::Person.transaction do
        super

        person.save!
        role.save!
        enqueue_duplicate_locator_job
        send_emails
      end
    end

    private

    def enqueue_duplicate_locator_job
      ::Person::DuplicateLocatorJob.new(person.id).enqueue!
    end

    def send_emails
      send_notification_email
      send_password_reset_email
    end

    def send_notification_email
      return if group.self_registration_notification_email.blank?

      ::Groups::SelfRegistrationNotificationMailer
        .self_registration_notification(group.self_registration_notification_email,
                                        entry.main_person.role).deliver_later
    end

    def send_password_reset_email
      return if entry.person.email.blank?

      Person.send_reset_password_instructions(email: entry.person.email)
    end
  end
end
