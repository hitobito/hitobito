#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::PassSynchronizer do
  let(:person) { people(:top_leader) }
  let(:definition) { pass_definitions(:top_layer_pass) }
  let(:pass) do
    Fabricate(:pass,
      person: person,
      pass_definition: definition,
      state: :eligible,
      valid_from: 1.month.ago.to_date)
  end
  let(:installation) do
    Fabricate(:wallets_pass_installation,
      pass: pass,
      wallet_type: wallet_type,
      needs_sync: true)
  end
  let(:wallet_type) { :google }

  subject(:synchronizer) { described_class.new(installation) }

  describe "#compute_validity!" do
    {
      "eligible" => "active",
      "ended" => "expired",
      "revoked" => "revoked"
    }.each do |pass_state, expected_installation_state|
      it "when pass is #{pass_state} sets installation state to #{expected_installation_state}" do
        pass.update!(state: pass_state)
        synchronizer.compute_validity!
        expect(installation.reload.state).to eq(expected_installation_state)
      end
    end

    it "with an unknown pass state raises an error" do
      pass.update_columns(state: "unknown")
      expect { synchronizer.compute_validity! }.to raise_error(RuntimeError, /Unexpected pass state/)
    end
  end

  describe "#sync!" do
    context "with a google installation" do
      let(:wallet_type) { :google }

      before do
        allow(Wallets::GoogleWallet::Config).to receive(:exist?).and_return(true)
      end

      context "when pass is eligible" do
        it "calls create_or_update on google pass service" do
          expect_any_instance_of(Wallets::GoogleWallet::PassService).to receive(:create_or_update)

          synchronizer.sync!
        end

        it "passes the installation to GoogleWallet::PassService" do
          expect(Wallets::GoogleWallet::PassService).to receive(:new)
            .with(installation)
            .and_call_original
          allow_any_instance_of(Wallets::GoogleWallet::PassService).to receive(:create_or_update)

          synchronizer.sync!
        end

        it "updates last_synced_at, clears sync_error and needs_sync" do
          allow_any_instance_of(Wallets::GoogleWallet::PassService).to receive(:create_or_update)

          synchronizer.sync!
          installation.reload

          expect(installation.last_synced_at).to be_within(2.seconds).of(Time.current)
          expect(installation.sync_error).to be_nil
          expect(installation.needs_sync).to be false
        end
      end

      context "when pass is ended" do
        before { pass.update!(state: "ended") }

        it "calls create_or_update for expired passes" do
          expect_any_instance_of(Wallets::GoogleWallet::PassService).to receive(:create_or_update)

          synchronizer.sync!
        end
      end

      context "when pass is revoked" do
        before { pass.update!(state: "revoked") }

        it "calls revoke on google pass service" do
          expect_any_instance_of(Wallets::GoogleWallet::PassService).to receive(:revoke)

          synchronizer.sync!
        end
      end

      context "with an unknown wallet type" do
        before { allow(installation).to receive(:wallet_type).and_return("unknown") }

        it "raises an error" do
          expect { synchronizer.sync! }.to raise_error(RuntimeError, /Unexpected wallet_type/)
        end
      end

      context "when provider raises an error" do
        it "stores sync_error and re-raises" do
          allow_any_instance_of(Wallets::GoogleWallet::PassService).to receive(:create_or_update).and_raise(
            StandardError, "API timeout"
          )

          expect { synchronizer.sync! }.to raise_error(StandardError, "API timeout")
          expect(installation.reload.sync_error).to eq("API timeout")
        end
      end
    end

    context "with an apple installation" do
      let(:wallet_type) { :apple }

      it "updates state without calling an external service (for now)" do
        synchronizer.sync!
        installation.reload

        expect(installation.state).to eq("active")
        expect(installation.last_synced_at).to be_within(2.seconds).of(Time.current)
        expect(installation.sync_error).to be_nil
      end

      it "sends push notification to update the pass" do
        expect_any_instance_of(Wallets::AppleWallet::PushService).to receive(:send_update_notification)

        synchronizer.sync!
      end
    end
  end

  describe ".sync_outdated!" do
    before do
      allow(Wallets::GoogleWallet::Config).to receive(:exist?).and_return(true)
      allow_any_instance_of(Wallets::GoogleWallet::PassService).to receive(:create_or_update)
      allow_any_instance_of(Wallets::GoogleWallet::PassService).to receive(:revoke)
    end

    let!(:synced_installation) do
      Fabricate(:wallets_pass_installation,
        pass: Fabricate.build(:pass, person: Fabricate(:person), pass_definition: definition, state: "eligible"),
        wallet_type: wallet_type,
        needs_sync: false)
    end

    let!(:outdated_installation) do
      Fabricate(:wallets_pass_installation,
        pass: Fabricate.build(:pass, person: Fabricate(:person), pass_definition: definition, state: "eligible"),
        wallet_type: wallet_type,
        needs_sync: true)
    end

    it "syncs all installations that need sync" do
      expect { described_class.sync_outdated! }.to change {
        outdated_installation.reload.needs_sync
      }.from(true).to(false)
    end

    it "does not sync installations that don't need sync" do
      expect { described_class.sync_outdated! }.not_to change { synced_installation.reload.needs_sync }
    end

    it "includes pass association to prevent N+1 queries" do
      relation = double("relation")
      allow(Wallets::PassInstallation).to receive(:needs_sync).and_return(relation)
      expect(relation).to receive(:includes).with(:pass).and_return(relation)
      expect(relation).to receive(:find_each).and_yield(outdated_installation)

      allow_any_instance_of(described_class).to receive(:sync!)

      described_class.sync_outdated!
    end

    it "logs errors for failed installations but continues processing" do
      allow_any_instance_of(described_class).to receive(:sync!).and_raise(StandardError, "Sync failed")

      expect(Rails.logger).to receive(:error).at_least(:once).with(
        /PassSynchronizer: Failed to sync PassInstallation#\d+: Sync failed/
      )

      expect { described_class.sync_outdated! }.not_to raise_error
    end
  end

  describe "#mark_for_sync!" do
    it "sets needs_sync flag" do
      installation.update!(state: :active)
      synchronizer.mark_for_sync!
      expect(installation.reload.needs_sync).to be true
    end
  end
end
