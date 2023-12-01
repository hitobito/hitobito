# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistration::MainPerson < SelfRegistration::Housemate
  self.attrs = [
    :first_name, :last_name, :nickname, :company_name, :company, :email,
    :privacy_policy_accepted
  ]

  self.required_attrs = [
    :first_name, :last_name
  ]

  attr_accessor(*attrs)

  delegate :phone_numbers, :gender_label, :privacy_policy_accepted?, to: :person
  validate :assert_privacy_policy

  def person
    @person ||= Person.new(attributes)
  end

  private

  def assert_privacy_policy
    if privacy_policy_accepted&.to_i&.zero?
      message = I18n.t('groups.self_registration.create.flash.privacy_policy_not_accepted')
      errors.add(:base, message)
    end
  end
end
