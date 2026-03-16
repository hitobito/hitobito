# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Wallets::PassInstallation < ActiveRecord::Base
  before_validation :generate_authentication_token, if: :apple?, on: :create
  before_save :set_needs_sync_on_state_transition

  belongs_to :pass
  has_many :device_registrations,
    class_name: "Wallets::AppleWallet::DeviceRegistration",
    dependent: :destroy

  delegate :person, :pass_definition, :valid_from, :valid_until, to: :pass

  enum :wallet_type, {google: 0, apple: 1}
  enum :state, {active: 0, expired: 1, revoked: 2}

  validates :pass_id, uniqueness: {scope: :wallet_type}
  validates :locale, presence: true
  validates :authentication_token, presence: true, if: :apple?

  # Installations that require a sync push to the wallet provider.
  # The flag is set automatically when state transitions by the before_save callback.
  # It is cleared by the sync job after a successful push.
  scope :needs_sync, -> { where(needs_sync: true) }

  private

  def generate_authentication_token
    self.authentication_token ||= SecureRandom.hex(32)
  end

  def set_needs_sync_on_state_transition
    self.needs_sync = true if state_changed?
  end
end
