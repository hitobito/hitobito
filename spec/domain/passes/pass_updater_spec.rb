# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Passes::PassUpdater do
  let(:person) { people(:top_leader) }
  let(:definition) { pass_definitions(:top_layer_pass) }
  let(:grant) { pass_grants(:top_layer_grant) }
  let(:role) { roles(:top_leader) }
  let(:updater) { described_class.new(role) }

  before do
    allow_any_instance_of(PassPopulateJob).to receive(:enqueue!)
  end

  describe "#run" do
    context "when person has no passes" do
      it "returns early without querying eligibility" do
        expect(updater.role.person.passes).to be_empty

        expect(Passes::Subscribers).not_to receive(:affected_passes)
        updater.run
      end
    end

    context "when person has unrelated passes" do
      let!(:unrelated_def) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
      let!(:unrelated_grant) do
        Fabricate(:pass_grant,
          pass_definition: unrelated_def,
          grantor: groups(:top_group)).tap do |g|
          g.role_types = [Group::TopGroup::Secretary.sti_name]
        end
      end
      let!(:pass) do
        Fabricate(:pass,
          person: person,
          pass_definition: unrelated_def,
          state: :eligible,
          valid_from: 1.month.ago.to_date)
      end

      it "does not change unrelated passes" do
        updater.run
        expect(pass.reload.state).to eq("eligible")
      end
    end

    context "when person has affected passes" do
      let!(:pass) do
        Fabricate(:pass,
          person: person,
          pass_definition: definition,
          state: :eligible,
          valid_from: 1.month.ago.to_date)
      end

      it "keeps pass eligible when role is active" do
        updater.run
        expect(pass.reload.state).to eq("eligible")
      end

      it "sets pass to ended when role has ended" do
        role.update_columns(end_on: 1.day.ago.to_date, start_on: 2.months.ago.to_date)
        role.reload

        updater.run
        expect(pass.reload.state).to eq("ended")
      end

      it "updates valid_from and valid_until" do
        role.update_columns(start_on: 6.months.ago.to_date, end_on: 1.month.from_now.to_date)
        role.reload

        updater.run
        pass.reload
        expect(pass.valid_from).to eq(6.months.ago.to_date)
        expect(pass.valid_until).to eq(1.month.from_now.to_date)
      end

      it "marks active installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass: pass,
          wallet_type: :google,
          state: :active)

        updater.run
        expect(installation.reload.needs_sync).to be true
      end

      it "does not mark revoked installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass: pass,
          wallet_type: :google,
          state: :revoked)

        updater.run
        expect(installation.reload.state).to eq("revoked")
      end

      it "marks expired installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass: pass,
          wallet_type: :apple,
          state: :expired)

        updater.run
        expect(installation.reload.needs_sync).to be true
      end
    end
  end
end
