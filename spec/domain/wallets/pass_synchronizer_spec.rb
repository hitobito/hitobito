#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::PassSynchronizer do
  let(:person) { people(:top_leader) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:membership) do
    Fabricate(:pass_membership,
      person: person,
      pass_definition: definition,
      state: membership_state,
      valid_from: 1.month.ago.to_date)
  end
  let(:installation) do
    Fabricate(:wallets_pass_installation,
      pass_membership: membership,
      wallet_type: wallet_type,
      state: :pending_sync)
  end
  let(:wallet_type) { :google }
  let(:membership_state) { :eligible }

  subject(:synchronizer) { described_class.new(installation) }

  describe "#compute_validity!" do
    context "when membership is eligible" do
      let(:membership_state) { :eligible }

      it "sets installation state to active" do
        synchronizer.compute_validity!
        expect(installation.reload.state).to eq("active")
      end
    end

    context "when membership is ended" do
      let(:membership_state) { :ended }

      it "sets installation state to expired" do
        synchronizer.compute_validity!
        expect(installation.reload.state).to eq("expired")
      end
    end

    context "when membership is revoked" do
      let(:membership_state) { :revoked }

      it "sets installation state to revoked" do
        synchronizer.compute_validity!
        expect(installation.reload.state).to eq("revoked")
      end
    end
  end

  describe "#sync!" do
    before do
      stub_const("Wallets::GoogleWallet::PassService", Class.new)
    end

    context "with a google installation" do
      let(:wallet_type) { :google }

      context "when membership is eligible" do
        let(:membership_state) { :eligible }

        it "calls create_or_update on google pass service" do
          service = instance_double("Wallets::GoogleWallet::PassService")
          allow(Wallets::GoogleWallet::PassService).to receive(:new).and_return(service)
          expect(service).to receive(:create_or_update)

          synchronizer.sync!
        end

        it "updates last_synced_at and clears sync_error" do
          service = instance_double("Wallets::GoogleWallet::PassService")
          allow(Wallets::GoogleWallet::PassService).to receive(:new).and_return(service)
          allow(service).to receive(:create_or_update)

          synchronizer.sync!
          installation.reload

          expect(installation.last_synced_at).to be_within(2.seconds).of(Time.current)
          expect(installation.sync_error).to be_nil
        end
      end

      context "when membership is ended" do
        let(:membership_state) { :ended }

        it "calls create_or_update for expired passes" do
          service = instance_double("Wallets::GoogleWallet::PassService")
          allow(Wallets::GoogleWallet::PassService).to receive(:new).and_return(service)
          expect(service).to receive(:create_or_update)

          synchronizer.sync!
        end
      end

      context "when membership is revoked" do
        let(:membership_state) { :revoked }

        it "calls revoke on google pass service" do
          service = instance_double("Wallets::GoogleWallet::PassService")
          allow(Wallets::GoogleWallet::PassService).to receive(:new).and_return(service)
          expect(service).to receive(:revoke)

          synchronizer.sync!
        end
      end

      context "when provider raises an error" do
        let(:membership_state) { :eligible }

        it "stores sync_error and re-raises" do
          service = instance_double("Wallets::GoogleWallet::PassService")
          allow(Wallets::GoogleWallet::PassService).to receive(:new).and_return(service)
          allow(service).to receive(:create_or_update).and_raise(StandardError, "API timeout")

          expect { synchronizer.sync! }.to raise_error(StandardError, "API timeout")
          expect(installation.reload.sync_error).to eq("API timeout")
        end
      end
    end

    context "with an apple installation" do
      let(:wallet_type) { :apple }
      let(:membership_state) { :eligible }

      it "updates state without calling an external service (Phase 1 polling)" do
        synchronizer.sync!
        installation.reload

        expect(installation.state).to eq("active")
        expect(installation.last_synced_at).to be_within(2.seconds).of(Time.current)
        expect(installation.sync_error).to be_nil
      end
    end
  end

  describe "#mark_for_sync!" do
    let(:membership_state) { :eligible }

    before do
      installation.update!(state: :active)
    end

    it "sets state to pending_sync" do
      synchronizer.mark_for_sync!
      expect(installation.reload.state).to eq("pending_sync")
    end
  end
end
