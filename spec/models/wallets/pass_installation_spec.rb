# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Wallets::PassInstallation do
  let(:pass) { Fabricate.build(:pass, person: people(:top_leader)) }

  subject(:installation) { Fabricate.build(:wallets_pass_installation, pass:) }

  it "is valid with default attributes" do
    expect(installation).to be_valid
  end

  context "validations" do
    it "requires locale" do
      installation.locale = nil
      expect(installation).not_to be_valid
      expect(installation.errors[:locale]).to be_present
    end

    it "validates only one installation per pass and wallet_type" do
      installation.save!
      duplicate = Fabricate.build(:wallets_pass_installation, pass:)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:pass_id]).to be_present
    end

    it "allows same pass with different wallet_type" do
      installation.save!
      other = Fabricate.build(:wallets_pass_installation, pass:, wallet_type: :apple)
      expect(other).to be_valid
    end
  end

  context "authentication token" do
    it "generates authentication_token automatically" do
      new_installation = Fabricate.build(:wallets_pass_installation, pass:)
      new_installation.valid?
      expect(new_installation.authentication_token).to be_present
      expect(new_installation.authentication_token.length).to eq(32)
    end

    it "does not overwrite existing authentication_token" do
      installation.authentication_token = "custom-token"
      installation.save!
      expect(installation.authentication_token).to eq("custom-token")
    end

    it "enforces uniqueness of authentication_token" do
      installation.save!

      duplicate = Fabricate.build(:wallets_pass_installation,
        pass: Fabricate.build(:pass, person: people(:bottom_member)),
        authentication_token: installation.authentication_token)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:authentication_token]).to be_present
    end
  end

  context "::needs_sync" do
    it "includes installations with needs_sync flag" do
      installation.needs_sync = true
      installation.save!
      expect(Wallets::PassInstallation.needs_sync).to include(installation)
    end

    it "excludes installations without needs_sync flag" do
      installation.save!
      expect(Wallets::PassInstallation.needs_sync).not_to include(installation)
    end
  end

  context "needs_sync callback" do
    it "sets needs_sync when transitioning to expired" do
      installation.save!
      expect { installation.update!(state: :expired) }
        .to change { installation.needs_sync }.from(false).to(true)
    end

    it "sets needs_sync when transitioning to revoked" do
      installation.save!
      expect { installation.update!(state: :revoked) }
        .to change { installation.needs_sync }.from(false).to(true)
    end

    it "sets needs_sync when transitioning back to active" do
      installation.state = :expired
      installation.save!
      installation.update_column(:needs_sync, false)
      expect { installation.update!(state: :active) }
        .to change { installation.needs_sync }.from(false).to(true)
    end

    it "does not set needs_sync when state does not change" do
      installation.save!
      installation.update!(locale: "fr")
      expect(installation.needs_sync).to be false
    end
  end
end
