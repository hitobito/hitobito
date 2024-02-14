module SelfRegistration::AdultConsent
  extend ActiveSupport::Concern

  included do
    self.attrs += [:adult_consent]
    self.active_model_only += [:adult_consent]

    validates :adult_consent, acceptance: true, if: :requires_adult_consent?
  end

  def requires_adult_consent?
    primary_group&.self_registration_require_adult_consent
  end
end
