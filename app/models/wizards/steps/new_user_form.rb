module Wizards
  module Steps
    class NewUserForm < WizardStep
      include ValidatedEmail

      delegate :group, to: :wizard

      attribute :first_name, :string
      attribute :last_name, :string
      attribute :nickname, :string
      attribute :company_name, :string
      attribute :company, :string
      attribute :email, :string
      attribute :birthday, :date
      attribute :adult_consent, :boolean
      attribute :privacy_policy_accepted, :boolean

      validates_presence_of :group, :first_name, :last_name, :email
      validate :ensure_email_available

      validates_presence_of :adult_consent, if: :requires_adult_consent?
      validates_presence_of :privacy_policy_accepted, if: :requires_privacy_policy?

      def requires_adult_consent?
        group.self_registration_require_adult_consent?
      end

      def requires_privacy_policy?
        privacy_policy_finder.acceptance_needed?
      end

      def privacy_policy_finder
        @privacy_policy_finder ||= Group::PrivacyPolicyFinder.for(group: group, person: wizard.person)
      end

      private

      # #email_changed? is used in `ValidatedEmail` to determine if the email should be validated.
      # Here it should only be validated if the email is present.
      def email_changed?
        email.present?
      end

      def ensure_email_available
        unless Person.where(email: email).none?
          errors.add(:email, I18n.t('activerecord.errors.models.person.attributes.email.taken'))
        end
      end
    end
  end
end
