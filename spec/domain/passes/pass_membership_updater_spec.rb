#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Passes::PassMembershipUpdater do
  let(:person) { people(:top_leader) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }

  before do
    allow_any_instance_of(PassMembershipPopulateJob).to receive(:enqueue!)
  end

  let!(:grant) do
    Fabricate(:pass_grant,
      pass_definition: definition,
      grantor: groups(:top_group)).tap do |g|
      g.role_types = [Group::TopGroup::Leader.sti_name]
    end
  end

  let(:role) { roles(:top_leader) }
  let(:updater) { described_class.new(person, role) }

  describe "#run" do
    context "when person has no pass_memberships" do
      it "returns early without querying eligibility" do
        expect(Wallets::PassEligibility).not_to receive(:affected_pass_memberships)
        updater.run
      end
    end

    context "when person has unrelated pass_memberships" do
      let!(:unrelated_def) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
      let!(:unrelated_grant) do
        Fabricate(:pass_grant,
          pass_definition: unrelated_def,
          grantor: groups(:top_group)).tap do |g|
          g.role_types = [Group::TopGroup::Secretary.sti_name]
        end
      end
      let!(:membership) do
        Fabricate(:pass_membership,
          person: person,
          pass_definition: unrelated_def,
          state: :eligible,
          valid_from: 1.month.ago.to_date)
      end

      it "does not change unrelated memberships" do
        updater.run
        expect(membership.reload.state).to eq("eligible")
      end
    end

    context "when person has affected pass_memberships" do
      let!(:membership) do
        Fabricate(:pass_membership,
          person: person,
          pass_definition: definition,
          state: :eligible,
          valid_from: 1.month.ago.to_date)
      end

      it "keeps membership eligible when role is active" do
        updater.run
        expect(membership.reload.state).to eq("eligible")
      end

      it "sets membership to ended when role has ended" do
        role.update_columns(end_on: 1.day.ago.to_date, start_on: 2.months.ago.to_date)
        role.reload

        updater.run
        expect(membership.reload.state).to eq("ended")
      end

      it "updates valid_from and valid_until" do
        role.update_columns(start_on: 6.months.ago.to_date, end_on: 1.month.from_now.to_date)
        role.reload

        updater.run
        membership.reload
        expect(membership.valid_from).to eq(6.months.ago.to_date)
        expect(membership.valid_until).to eq(1.month.from_now.to_date)
      end

      it "marks active installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass_membership: membership,
          wallet_type: :google,
          state: :active)

        updater.run
        expect(installation.reload.state).to eq("pending_sync")
      end

      it "does not mark revoked installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass_membership: membership,
          wallet_type: :google,
          state: :revoked)

        updater.run
        expect(installation.reload.state).to eq("revoked")
      end

      it "marks expired installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass_membership: membership,
          wallet_type: :apple,
          state: :expired)

        updater.run
        expect(installation.reload.state).to eq("pending_sync")
      end
    end
  end
end
