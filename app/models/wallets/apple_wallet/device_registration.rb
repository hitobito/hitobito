# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Wallets::AppleWallet::DeviceRegistration < ActiveRecord::Base
  # device_library_identifier: Unique identifier for the Apple device (provided by Apple PassKit).
  # push_token: APNs token for sending push notifications to this device when the pass updates.
  attr_readonly :device_library_identifier, :push_token

  ### ASSOCIATIONS

  belongs_to :pass_installation, class_name: "Wallets::PassInstallation"

  ### VALIDATIONS

  validates_by_schema
  validates :device_library_identifier, presence: true, uniqueness: {scope: :pass_installation_id}
  validates :push_token, presence: true
end
