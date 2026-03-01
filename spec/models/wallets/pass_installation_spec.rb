#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::PassInstallation do
  let(:membership) { Fabricate(:pass_membership) }

  subject(:installation) do
    Wallets::PassInstallation.new(
      pass_membership: membership,
      wallet_type: :google,
      state: :active,
      wallet_identifier: SecureRandom.uuid
    )
  end

  it "is valid with default attributes" do
    expect(installation).to be_valid
  end

  context "validations" do
    it "requires wallet_identifier" do
      installation.wallet_identifier = nil
      expect(installation).not_to be_valid
      expect(installation.errors[:wallet_identifier]).to be_present
    end

    it "validates wallet_identifier uniqueness per pass_membership and wallet_type" do
      installation.save!
      duplicate = Wallets::PassInstallation.new(
        pass_membership: membership,
        wallet_type: :google,
        wallet_identifier: installation.wallet_identifier
      )
      expect(duplicate).not_to be_valid
    end

    it "allows same wallet_identifier for different wallet_type" do
      installation.save!
      other = Wallets::PassInstallation.new(
        pass_membership: membership,
        wallet_type: :apple,
        wallet_identifier: "different-id"
      )
      expect(other).to be_valid
    end
  end

  context "enums" do
    it "supports google wallet_type" do
      installation.wallet_type = :google
      expect(installation).to be_google
    end

    it "supports apple wallet_type" do
      installation.wallet_type = :apple
      expect(installation).to be_apple
    end

    it "supports active state" do
      installation.state = :active
      expect(installation).to be_active
    end

    it "supports expired state" do
      installation.state = :expired
      expect(installation).to be_expired
    end

    it "supports revoked state" do
      installation.state = :revoked
      expect(installation).to be_revoked
    end

    it "supports pending_sync state" do
      installation.state = :pending_sync
      expect(installation).to be_pending_sync
    end
  end

  context "delegates" do
    it "delegates person to pass_membership" do
      expect(installation.person).to eq(membership.person)
    end

    it "delegates pass_definition to pass_membership" do
      expect(installation.pass_definition).to eq(membership.pass_definition)
    end

    it "delegates valid_from to pass_membership" do
      expect(installation.valid_from).to eq(membership.valid_from)
    end

    it "delegates valid_until to pass_membership" do
      expect(installation.valid_until).to eq(membership.valid_until)
    end
  end

  context "associations" do
    it "belongs to pass_membership" do
      expect(installation.pass_membership).to eq(membership)
    end

    it "has many device_registrations" do
      installation.wallet_type = :apple
      installation.save!
      reg = Fabricate(:wallets_apple_device_registration,
        pass_installation: installation)
      expect(installation.device_registrations).to include(reg)
    end

    it "destroys dependent device_registrations" do
      installation.wallet_type = :apple
      installation.save!
      Fabricate(:wallets_apple_device_registration,
        pass_installation: installation)
      expect { installation.destroy }
        .to change { Wallets::AppleWallet::DeviceRegistration.count }.by(-1)
    end
  end

  context "authentication token" do
    it "generates authentication_token for apple installations on create" do
      apple = Wallets::PassInstallation.create!(
        pass_membership: membership,
        wallet_type: :apple,
        wallet_identifier: SecureRandom.uuid
      )
      expect(apple.authentication_token).to be_present
      expect(apple.authentication_token.length).to eq(64)
    end

    it "does not generate authentication_token for google installations" do
      google = Wallets::PassInstallation.create!(
        pass_membership: membership,
        wallet_type: :google,
        wallet_identifier: SecureRandom.uuid
      )
      expect(google.authentication_token).to be_nil
    end

    it "does not overwrite existing authentication_token" do
      installation.wallet_type = :apple
      installation.authentication_token = "custom-token"
      installation.save!
      expect(installation.authentication_token).to eq("custom-token")
    end
  end

  context "scope needs_sync" do
    it "includes pending_sync installations" do
      installation.state = :pending_sync
      installation.save!
      expect(Wallets::PassInstallation.needs_sync).to include(installation)
    end

    it "excludes active installations" do
      installation.save!
      expect(Wallets::PassInstallation.needs_sync).not_to include(installation)
    end

    it "includes expired installations not yet synced" do
      installation.state = :expired
      installation.last_synced_at = nil
      installation.save!
      expect(Wallets::PassInstallation.needs_sync).to include(installation)
    end

    it "includes revoked installations updated after last sync" do
      installation.state = :revoked
      installation.last_synced_at = 1.hour.ago
      installation.save!
      # Touch the record to update updated_at after last_synced_at
      installation.touch
      expect(Wallets::PassInstallation.needs_sync).to include(installation)
    end
  end
end
