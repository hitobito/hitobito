# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "person/passes/show.html.haml" do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:pass) do
    Fabricate(:pass, person: person, pass_definition: definition,
      state: :eligible, valid_from: Date.current)
  end
  let(:current_user) { person }

  before do
    assign(:group, group)
    assign(:person, person)
    assign(:pass, pass.decorate)
    assign(:pass_definition, definition)
    allow(controller).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:google_wallet_configured?).and_return(false)
    allow(view).to receive(:apple_wallet_configured?).and_return(false)
    # Stub the template partial to avoid rendering the full card template
    allow(view).to receive(:pass_template_partial).and_return("people/passes/_show_stub")
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render)
      .with("people/passes/_show_stub")
      .and_return("<div class='pass-card-wrapper'>stub</div>")
    render
  end

  subject { Capybara::Node::Simple.new(rendered) }

  it "uses the pass definition name as the page title" do
    expect(view.title).to eq(definition.name)
  end

  it "delegates to the template partial" do
    expect(view).to have_received(:pass_template_partial)
      .with(definition.template_key, "show")
  end

  describe "toolbar action buttons" do
    subject { Capybara::Node::Simple.new(view.content_for(:toolbar)) }

    it "includes the PDF download link" do
      is_expected.to have_link(I18n.t("person.passes.index.download_pdf"))
    end

    it "does not show wallet buttons when wallets are not configured" do
      is_expected.not_to have_link(I18n.t("person.passes.index.add_to_google_wallet"))
      is_expected.not_to have_link(I18n.t("person.passes.index.add_to_apple_wallet"))
    end

    context "when google wallet is configured" do
      before do
        allow(view).to receive(:google_wallet_configured?).and_return(true)
        render
      end

      it "shows the Google Wallet button" do
        is_expected.to have_link(I18n.t("person.passes.index.add_to_google_wallet"))
      end
    end

    context "when apple wallet is configured" do
      before do
        allow(view).to receive(:apple_wallet_configured?).and_return(true)
        render
      end

      it "shows the Apple Wallet button" do
        is_expected.to have_link(I18n.t("person.passes.index.add_to_apple_wallet"))
      end
    end
  end
end
