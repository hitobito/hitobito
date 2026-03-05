#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Pass
  attr_reader :person, :definition

  def initialize(person:, definition:)
    @person = person
    @definition = definition
  end

  def eligible?
    eligibility.member?(person)
  end

  # Whether the person had matching roles that have since ended or been archived.
  # Archived roles count as "ended at archived_at". Used by PassSynchronizer
  # to distinguish expiry (ended/archived) from revocation (hard-deleted).
  def has_ended?
    !eligible? && eligibility.matching_roles_including_ended(person).exists?
  end

  def valid_from
    eligibility.matching_roles_including_ended(person).minimum(:start_on)&.to_date || Date.current
  end

  def valid_until
    eligibility.matching_roles_including_ended(person).maximum(:end_on)&.to_date
  end

  def valid?
    eligible? &&
      valid_from <= Date.current &&
      (valid_until.nil? || valid_until >= Date.current)
  end

  # Delegated to WalletDataProvider — allows wagon-specific overrides
  # (e.g., SAC uses person.membership_number instead of person.id).
  def member_number
    wallet_data_provider.member_number
  end

  # Delegated to WalletDataProvider — allows wagon-specific overrides.
  def member_name
    wallet_data_provider.member_name
  end

  def qrcode_value
    Passes::VerificationQrCode.new(person, definition).verify_url
  end

  def account_id
    "#{person.id}-#{definition.id}"
  end

  def to_s
    definition.name
  end

  def to_h
    {
      definition_id: definition.id,
      definition_name: definition.name,
      person_id: person.id,
      member_number: member_number,
      member_name: member_name,
      valid_from: valid_from,
      valid_until: valid_until,
      qrcode_value: qrcode_value
    }
  end

  def wallet_data_provider
    @wallet_data_provider ||= definition.template.wallet_data_provider.new(self)
  end

  private

  def eligibility
    @eligibility ||= Passes::PassEligibility.new(definition)
  end
end
