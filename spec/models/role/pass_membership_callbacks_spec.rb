#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Role pass membership callbacks" do
  let(:person) { people(:top_leader) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let!(:grant) do
    Fabricate(:pass_grant,
      pass_definition: definition,
      grantor: groups(:top_group)).tap do |g|
      g.role_types = [Group::TopGroup::Leader.sti_name]
    end
  end

  before do
    # Suppress the after_create PopulateJob enqueue from definition fabrication
    allow_any_instance_of(PassMembershipPopulateJob).to receive(:enqueue!)
  end

  describe "after_save" do
    context "when person has affected pass_memberships" do
      let!(:membership) do
        Fabricate(:pass_membership,
          person: person,
          pass_definition: definition,
          state: :eligible,
          valid_from: 1.month.ago.to_date)
      end

      it "keeps membership eligible when role is active" do
        # top_leader already has the Leader role (fixture)
        # Trigger callback by updating the role
        role = roles(:top_leader)
        role.update!(label: "updated")

        membership.reload
        expect(membership.state).to eq("eligible")
      end

      it "sets membership to ended when role end_on is set to the past" do
        role = roles(:top_leader)
        role.update!(end_on: 1.day.ago.to_date, start_on: 2.months.ago.to_date)

        membership.reload
        expect(membership.state).to eq("ended")
      end

      it "sets membership to ended when role is archived" do
        role = roles(:top_leader)
        Role.where(id: role.id).update_all(archived_at: 1.day.ago)
        # Trigger after_save by saving again with a minor change
        role.reload

        # Create a new role and archive it to test the callback
        new_role = Fabricate(:role,
          person: person,
          group: groups(:top_group),
          type: Group::TopGroup::Leader.sti_name)
        Role.where(id: new_role.id).update_all(archived_at: 1.day.ago)
        new_role.reload
        new_role.destroy

        membership.reload
        expect(membership.state).to eq("ended")
      end

      it "marks pass_installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass_membership: membership,
          wallet_type: :google,
          state: :active)

        role = roles(:top_leader)
        role.update!(label: "trigger callback")

        expect(installation.reload.state).to eq("pending_sync")
      end

      it "does not mark revoked installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass_membership: membership,
          wallet_type: :google,
          state: :revoked)

        role = roles(:top_leader)
        role.update!(label: "trigger callback")

        expect(installation.reload.state).to eq("revoked")
      end
    end

    context "when person has no pass_memberships" do
      it "does not raise" do
        role = roles(:top_leader)
        expect { role.update!(label: "no memberships") }.not_to raise_error
      end
    end

    context "when role does not match any pass definition" do
      let!(:membership) do
        Fabricate(:pass_membership,
          person: person,
          pass_definition: definition,
          state: :eligible,
          valid_from: 1.month.ago.to_date)
      end

      it "does not change membership when role type is unrelated" do
        # Create a Secretary grant (unrelated to Leader role)
        unrelated_def = Fabricate(:pass_definition, owner: groups(:top_layer))
        Fabricate(:pass_grant,
          pass_definition: unrelated_def,
          grantor: groups(:top_group)).tap do |g|
          g.role_types = [Group::TopGroup::Secretary.sti_name]
        end
        unrelated_membership = Fabricate(:pass_membership,
          person: person,
          pass_definition: unrelated_def,
          state: :eligible,
          valid_from: 1.month.ago.to_date)

        # Update the Leader role — should not affect Secretary-based membership
        role = roles(:top_leader)
        role.update!(label: "unrelated change")

        expect(unrelated_membership.reload.state).to eq("eligible")
      end
    end
  end

  describe "after_destroy" do
    context "when person has affected pass_memberships" do
      let!(:membership) do
        Fabricate(:pass_membership,
          person: person,
          pass_definition: definition,
          state: :eligible,
          valid_from: 1.month.ago.to_date)
      end

      it "sets membership to revoked when role is destroyed" do
        role = roles(:top_leader)
        role.destroy

        membership.reload
        expect(membership.state).to eq("revoked")
      end

      it "marks pass_installations for sync on role destruction" do
        installation = Fabricate(:wallets_pass_installation,
          pass_membership: membership,
          wallet_type: :apple,
          state: :active)

        role = roles(:top_leader)
        role.destroy

        expect(installation.reload.state).to eq("pending_sync")
      end
    end
  end
end
