#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Passes::DefinitionChangeHandler do
  let(:definition) { pass_definitions(:top_layer_pass) }
  let(:grant) { pass_grants(:top_layer_grant) }
  let(:person) { people(:top_leader) }

  before do
    allow_any_instance_of(PassPopulateJob).to receive(:enqueue!)
  end

  let!(:pass) do
    Fabricate(:pass,
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
            pass: pass,
            wallet_type: :google,
            state: :active)

          new_value = (attr == "background_color") ? "#ff0000" : "new_#{attr}_value"

          definition.update!(attr => new_value)

          expect(installation.reload.needs_sync).to be true
        end
      end

      it "marks installations for sync when template_key changes" do
        alt_pdf_class = Class.new
        Passes::TemplateRegistry.register("alt",
          pdf_class: alt_pdf_class,
          pass_view_partial: "default",
          wallet_data_provider: Passes::WalletDataProvider)

        installation = Fabricate(:wallets_pass_installation,
          pass: pass,
          wallet_type: :google,
          state: :active)

        definition.update!(template_key: "alt")

        expect(installation.reload.needs_sync).to be true
      end

      it "marks multiple installations across passs" do
        another_person = people(:bottom_member)
        another_pass = Fabricate(:pass,
          person: another_person,
          pass_definition: definition,
          state: :eligible,
          valid_from: 1.month.ago.to_date)

        installation1 = Fabricate(:wallets_pass_installation,
          pass: pass,
          wallet_type: :google,
          state: :active)
        installation2 = Fabricate(:wallets_pass_installation,
          pass: another_pass,
          wallet_type: :apple,
          state: :active)

        definition.update!(name: "Updated Pass Name")

        expect(installation1.reload.needs_sync).to be true
        expect(installation2.reload.needs_sync).to be true
      end
    end

    context "when non-sync attributes change" do
      it "does not mark installations for sync" do
        installation = Fabricate(:wallets_pass_installation,
          pass: pass,
          wallet_type: :google,
          state: :active)

        # owner_id is not in SYNC_ATTRIBUTES
        definition.update!(owner: groups(:bottom_layer_one))

        expect(installation.reload.needs_sync).to be false
      end
    end

    context "when pass is not eligible" do
      it "does not mark ended pass installations for sync" do
        pass.update!(state: :ended)

        installation = Fabricate(:wallets_pass_installation,
          pass: pass,
          wallet_type: :google,
          state: :expired)

        definition.update!(name: "Changed Name")

        expect(installation.reload.state).to eq("expired")
      end
    end
  end
end
