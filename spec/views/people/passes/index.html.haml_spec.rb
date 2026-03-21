#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "people/passes/index.html.haml" do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:current_user) { person }

  before do
    assign(:group, group)
    assign(:person, person)
    allow(controller).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:google_wallet_configured?).and_return(false)
    allow(view).to receive(:apple_wallet_configured?).and_return(false)
  end

  subject { Capybara::Node::Simple.new(rendered) }

  context "when person has no passes" do
    before do
      assign(:passes, [])
      render
    end

    it "shows the empty state message" do
      expect(rendered).to include(I18n.t("people.passes.index.no_passes"))
    end

    it "does not render a table" do
      is_expected.not_to have_css("table")
    end
  end

  context "when person has passes" do
    let!(:pass) do
      Fabricate(:pass, person: person, pass_definition: definition,
        state: :eligible, valid_from: Date.new(2026, 1, 1))
    end

    before do
      assign(:passes, [pass])
      render
    end

    it "renders the pass definition name" do
      is_expected.to have_content(definition.name)
    end

    it "renders a table" do
      is_expected.to have_css("table")
    end

    it "includes a link to the show action" do
      is_expected.to have_link(I18n.t("people.passes.index.show_pass"))
    end

    it "includes a PDF download link" do
      is_expected.to have_link(I18n.t("people.passes.index.download_pdf"))
    end

    it "formats the valid_from date" do
      is_expected.to have_content(I18n.l(Date.new(2026, 1, 1)))
    end

    it "does not show wallet buttons when wallets are not configured" do
      is_expected.not_to have_link(I18n.t("people.passes.index.add_to_google_wallet"))
      is_expected.not_to have_link(I18n.t("people.passes.index.add_to_apple_wallet"))
    end

    context "when google wallet is configured" do
      before do
        allow(view).to receive(:google_wallet_configured?).and_return(true)
        render
      end

      it "shows the Google Wallet button" do
        is_expected.to have_content(I18n.t("people.passes.index.add_to_google_wallet"))
      end
    end

    context "when apple wallet is configured" do
      before do
        allow(view).to receive(:apple_wallet_configured?).and_return(true)
        render
      end

      it "shows the Apple Wallet button" do
        is_expected.to have_content(I18n.t("people.passes.index.add_to_apple_wallet"))
      end
    end
  end
end
