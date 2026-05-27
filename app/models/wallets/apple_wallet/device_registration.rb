# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# == Schema Information
#
# Table name: wallets_apple_device_registrations
#
#  id                        :bigint           not null, primary key
#  device_library_identifier :string           not null
#  push_token                :string           not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  pass_installation_id      :bigint           not null
#
# Indexes
#
#  idx_wallets_apple_device_reg_unique  (device_library_identifier,pass_installation_id) UNIQUE
#
class Wallets::AppleWallet::DeviceRegistration < ActiveRecord::Base
  # push_token: APNs token for sending push notifications to this device when the pass updates.
  # device_library_identifier: Unique identifier for the Apple device (provided by Apple PassKit).
  attr_readonly :device_library_identifier

  ### ASSOCIATIONS

  belongs_to :pass_installation, class_name: "Wallets::PassInstallation"

  ### VALIDATIONS

  validates_by_schema
  validates :device_library_identifier, presence: true, uniqueness: {scope: :pass_installation_id}
  validates :push_token, presence: true
end
