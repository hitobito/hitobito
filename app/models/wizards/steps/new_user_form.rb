# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Wizards::Steps::NewUserForm < Wizards::Step
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :nickname, :string
  attribute :company_name, :string
  attribute :company, :boolean
  attribute :email, :string
  attribute :adult_consent, :boolean
  attribute :privacy_policy_accepted, :boolean

  validates :first_name, :last_name, presence: true
  validates :adult_consent, acceptance: true, if: :requires_adult_consent?
  validates :company_name, presence: true, if: :company
  validate :assert_privacy_policy, if: :requires_policy_acceptance?

  delegate :requires_adult_consent?, :requires_policy_acceptance?, to: :wizard

  class_attribute :support_company, default: true

  def self.human_attribute_name(attr, options = {})
    super(attr, default: Person.human_attribute_name(attr, options))
  end

  def assignable_attributes
    attributes.compact_blank.symbolize_keys.except(:adult_consent)
  end

  private

  def assert_privacy_policy
    unless privacy_policy_accepted
      message = I18n.t("groups.self_registration.create.flash.privacy_policy_not_accepted")
      errors.add(:base, message)
    end
  end
end
