# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Wizards::Steps::NewEventGuestContactDataForm < Wizards::Step
  include ValidatedEmail

  attribute :first_name, :string
  attribute :last_name, :string
  attribute :nickname, :string
  attribute :company_name, :string
  attribute :email, :string
  attribute :address_care_of, :string
  attribute :street, :string
  attribute :housenumber, :string
  attribute :postbox, :string
  attribute :zip_code, :string
  attribute :town, :string
  attribute :country, :string
  attribute :gender, :string
  attribute :birthday, :date
  attribute :phone_number, :string
  attribute :language, :string
  attribute :privacy_policy_accepted, :boolean

  ### VALIDATIONS
  before_validation :format_number
  Event.possible_contact_attrs.excluding(:phone_numbers).each do |attr|
    validates attr, presence: true,
      if: proc { |step| step.wizard.event.required_contact_attr?(attr) }
  end
  validates :phone_number, presence: true,
    if: proc { |step| step.wizard.event.required_contact_attr?(:phone_numbers) }

  validates :email, length: {maximum: 255}
  validates :language, inclusion: {in: Person::LANGUAGES.keys.map(&:to_s), allow_blank: true}
  validates :birthday,
    timeliness: {type: :date, allow_blank: true, before: Date.new(10_000, 1, 1)}
  validates :phone_number, phone: true, allow_blank: true
  validate :assert_privacy_policy, if: :requires_policy_acceptance?

  delegate :requires_policy_acceptance?, to: :wizard

  def mark_as_required?(attr)
    return mark_as_required?(:phone_numbers) if attr.to_sym == :phone_number
    wizard.event.required_contact_attr?(attr)
  end

  def self.human_attribute_name(attr, options = {})
    super(attr, default: Event::Guest.human_attribute_name(attr, options))
  end

  def email_changed?
    true
  end

  def format_number
    phone = Phonelib.parse(phone_number)
    if phone.valid?
      self.phone_number = phone.international
    end
  end

  private

  def assert_privacy_policy
    unless privacy_policy_accepted
      message = I18n.t(".flash.privacy_policy_not_accepted")
      errors.add(:base, message)
    end
  end
end
