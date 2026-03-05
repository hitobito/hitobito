#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Passes::DefinitionChangeHandler do
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:person) { people(:top_leader) }

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

  let!(:membership) do
    Fabricate(:pass_membership,
      person: person,
      pass_definition: definition,
      state: :eligible,
      valid_from: 1.month.ago.to_date)
  end

  describe "#handle_update" do
    context "when sync-relevant attributes change" do
      %w[name description background_color].each do |attr|
        it "marks installations for sync when #{attr} changes" do
          installation = Fabricate(:wallets_pass_installation,
            pass_membership: membership,
            wallet_type: :google,
            state: :active)

          new_value = (attr == "background_color") ? "#ff0000" : "new_#{attr}_value"

          definition.update!(attr => new_value)

          expect(installation.reload.state).to eq("pending_sync")
        end
      end

      it "marks installations for sync when template_key changes" do
        alt_pdf_class = Class.new
        Passes::TemplateRegistry.register("alt",
          pdf_class: alt_pdf_class,
          pass_view_partial: "default",
          wallet_data_provider: Passes::WalletDataProvider)

        installation = Fabricate(:wallets_pass_installation,
          pass_membership: membership,
          wallet_type: :google,
          state: :active)

        definition.update!(template_key: "alt")

        expect(installation.reload.state).to eq("pending_sync")
      end

      it "marks multiple installations across memberships" do
        another_person = people(:bottom_member)
        another_membership = Fabricate(:pass_membership,
          person: another_person,
          pass_definition: definition,
          state: :eligible,
          valid_from: 1.month.ago.to_date)

        installation1 = Fabricate(:wallets_pass_installation,
          pass_membership: membership,
          wallet_type: :google,
          state: :active)
        installation2 = Fabricate(:wallets_pass_installation,
          pass_membership: another_membership,
          wallet_type: :apple,
          state: :active)

        definition.update!(name: "Updated Pass Name")

        expect(installation1.reload.state).to eq("pending_sync")
        expect(installation2.reload.state).to eq("pending_sync")
      end
    end

    context "when non-sync attributes change" do
      it "does not mark installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass_membership: membership,
          wallet_type: :google,
          state: :active)

        # owner_id is not in SYNC_ATTRIBUTES; reload clears Globalize dirty state from fabrication
        definition.reload
        definition.update!(owner: groups(:bottom_layer_one))

        expect(installation.reload.state).to eq("active")
      end
    end

    context "when membership is not eligible" do
      it "does not mark ended membership installations for sync" do
        membership.update_columns(state: PassMembership.states[:ended])

        installation = Fabricate(:wallets_pass_installation,
          pass_membership: membership,
          wallet_type: :google,
          state: :expired)

        definition.update!(name: "Changed Name")

        expect(installation.reload.state).to eq("expired")
      end
    end

    context "with no installations" do
      it "does not raise" do
        expect { definition.update!(name: "No Installations") }.not_to raise_error
      end
    end
  end

  describe "#sync_needed?" do
    it "returns true when SYNC_ATTRIBUTES change" do
      definition.update!(name: "New Name")
      handler = described_class.new(definition)

      expect(handler.send(:sync_needed?)).to be true
    end
  end
end
