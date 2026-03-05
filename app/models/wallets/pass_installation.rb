#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Wallets::PassInstallation < ActiveRecord::Base
  belongs_to :pass_membership
  has_many :device_registrations,
    class_name: "Wallets::AppleWallet::DeviceRegistration",
    dependent: :destroy

  delegate :person, :pass_definition, :valid_from, :valid_until, :pass, to: :pass_membership

  enum :wallet_type, {google: 0, apple: 1}
  enum :state, {active: 0, expired: 1, revoked: 2, pending_sync: 3}

  validates :wallet_identifier, presence: true,
    uniqueness: {scope: [:pass_membership_id, :wallet_type]}

  scope :needs_sync, -> {
    where(state: :pending_sync)
      .or(where(state: [:expired, :revoked])
      .where("last_synced_at IS NULL OR last_synced_at < wallets_pass_installations.updated_at"))
  }

  before_create :generate_authentication_token, if: :apple?

  private

  def generate_authentication_token
    self.authentication_token ||= SecureRandom.hex(32)
  end
end
