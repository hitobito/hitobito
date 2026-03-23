# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Wallets::AppleWallet::DeviceRegistration do
  let(:installation) do
    Fabricate.build(:wallets_pass_installation, wallet_type: :apple)
  end

  subject(:registration) do
    Wallets::AppleWallet::DeviceRegistration.new(
      pass_installation: installation,
      device_library_identifier: SecureRandom.hex(16),
      push_token: SecureRandom.hex(32)
    )
  end

  it "is valid with default attributes" do
    expect(registration).to be_valid
  end

  context "validations" do
    it "requires device_library_identifier" do
      registration.device_library_identifier = nil
      expect(registration).not_to be_valid
      expect(registration.errors[:device_library_identifier]).to be_present
    end

    it "requires push_token" do
      registration.push_token = nil
      expect(registration).not_to be_valid
      expect(registration.errors[:push_token]).to be_present
    end

    it "validates device_library_identifier uniqueness per pass_installation" do
      registration.save!
      duplicate = Wallets::AppleWallet::DeviceRegistration.new(
        pass_installation: installation,
        device_library_identifier: registration.device_library_identifier,
        push_token: SecureRandom.hex(32)
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:device_library_identifier]).to be_present
    end

    it "allows same device_library_identifier for different pass_installation" do
      registration.save!
      other_installation = Fabricate(:wallets_pass_installation, wallet_type: :apple)
      other = Wallets::AppleWallet::DeviceRegistration.new(
        pass_installation: other_installation,
        device_library_identifier: registration.device_library_identifier,
        push_token: SecureRandom.hex(32)
      )
      expect(other).to be_valid
    end
  end
end
