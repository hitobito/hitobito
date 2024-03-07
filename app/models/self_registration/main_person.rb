# frozen_string_literal: true

#  Copyright (c) 2023-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistration::MainPerson < SelfRegistration::Person

  self.attrs = [
    :first_name, :last_name, :nickname, :company_name, :company, :email,
    :adult_consent,
    :privacy_policy_accepted,
    :primary_group,
  ]

  self.required_attrs = [
    :first_name, :last_name
  ]

  self.active_model_only = [:adult_consent]

  delegate :phone_numbers, :privacy_policy_accepted?, to: :person
  validate :assert_privacy_policy
  validates :adult_consent, acceptance: true, if: :requires_adult_consent?

  def requires_adult_consent?
    primary_group&.self_registration_require_adult_consent
  end

  private

  def assert_privacy_policy
    if privacy_policy_accepted&.to_i&.zero?
      message = I18n.t('groups.self_registration.create.flash.privacy_policy_not_accepted')
      errors.add(:base, message)
    end
  end
end
