# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "Role pass callbacks" do
  let(:person) { people(:top_leader) }
  let(:definition) { pass_definitions(:top_layer_pass) }
  let(:grant) { pass_grants(:top_layer_grant) }

  before do
    allow_any_instance_of(PassPopulateJob).to receive(:enqueue!)
  end

  describe "after_save" do
    context "when person has affected passes" do
      let!(:pass) do
        Fabricate(:pass,
          person: person,
          pass_definition: definition,
          state: :eligible,
          valid_from: 1.month.ago.to_date)
      end

      it "keeps pass eligible when role is active" do
        roles(:top_leader).update!(label: "updated")

        expect(pass.reload.state).to eq("eligible")
      end

      it "sets pass to ended when role end_on is set to the past" do
        roles(:top_leader).update!(end_on: 1.day.ago.to_date, start_on: 2.months.ago.to_date)

        expect(pass.reload.state).to eq("ended")
      end

      it "sets pass to ended when role is archived" do
        roles(:top_leader).update(archived_at: 1.day.ago)

        expect(pass.reload.state).to eq("ended")
      end

      it "marks pass_installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass: pass,
          wallet_type: :google,
          state: :active)

        roles(:top_leader).update!(label: "trigger callback")

        expect(installation.reload.needs_sync).to be true
      end

      it "does not mark revoked installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass: pass,
          wallet_type: :google,
          state: :revoked)

        roles(:top_leader).update!(label: "trigger callback")

        expect(installation.reload.state).to eq("revoked")
      end
    end

    context "when role does not match any pass definition" do
      let!(:pass) do
        Fabricate(:pass,
          person: person,
          pass_definition: definition,
          state: :eligible,
          valid_from: 1.month.ago)
      end

      it "does not change pass when role type is unrelated" do
        # Create a Secretary grant (unrelated to Leader role)
        unrelated_def = Fabricate(:pass_definition, owner: groups(:top_layer))
        Fabricate(:pass_grant,
          pass_definition: unrelated_def,
          grantor: groups(:top_group)).tap do |g|
          g.role_types = [Group::TopGroup::Secretary.sti_name]
        end
        unrelated_pass = Fabricate(:pass,
          person: person,
          pass_definition: unrelated_def,
          state: :eligible,
          valid_from: 1.month.ago.to_date)

        # Update the Leader role — should not affect Secretary-based pass
        roles(:top_leader).update!(end_on: 1.day.ago)

        expect(unrelated_pass.reload.state).to eq("eligible")
      end
    end
  end

  describe "after_destroy" do
    context "when person has affected passes" do
      let!(:pass) do
        Fabricate(:pass,
          person: person,
          pass_definition: definition,
          state: :eligible,
          valid_from: 1.month.ago.to_date)
      end

      it "sets pass to revoked when role is destroyed" do
        role = roles(:top_leader)
        role.destroy

        pass.reload
        expect(pass.state).to eq("revoked")
      end

      it "marks pass_installations for sync on role destruction" do
        installation = Fabricate(:wallets_pass_installation,
          pass: pass,
          wallet_type: :apple,
          state: :active)

        role = roles(:top_leader)
        role.destroy

        expect(installation.reload.needs_sync).to be true
      end
    end
  end
end
