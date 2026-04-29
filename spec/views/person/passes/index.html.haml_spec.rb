# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "person/passes/index.html.haml" do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }

  subject(:dom) { Capybara::Node::Simple.new(render) }

  context "when person has no passes" do
    let(:entries) { [] }

    before do
      allow(view).to receive_messages(entries: [])
    end

    it "shows the empty state message" do
      expect(dom).to have_css "div.table", text: "Keine Einträge gefunden."
    end
  end

  context "when person has passes" do
    let(:pass) do
      Fabricate(:pass, person: person, pass_definition: definition,
        state: :eligible, valid_from: Date.new(2026, 1, 1))
    end

    before do
      params[:group_id] = group.id
      params[:person_id] = person.id
      allow(view).to receive_messages(
        entries: [pass],
        parents: [group, person],
        sortable?: true,
        google_wallet_configured?: false,
        apple_wallet_configured?: false
      )
    end

    it "renders a table with info link to pass and action to print" do
      expect(dom).to have_css "table"
      expect(dom).to have_text "Gültig"
      expect(dom).to have_link "Drucken"
      expect(dom).to have_content(I18n.l(Date.new(2026, 1, 1)))
      expect(dom).to have_link definition.name, href: group_person_pass_path(group, person, pass)
    end

    it "does not show wallet buttons when wallets are not configured" do
      expect(dom).not_to have_link("Google Wallet")
      expect(dom).not_to have_link("Apple Wallet")
    end

    it "does show wallet buttons when wallets are configured" do
      allow(view).to receive(:google_wallet_configured?).and_return(true)
      allow(view).to receive(:apple_wallet_configured?).and_return(true)
      expect(dom).to have_link("Google Wallet")
      expect(dom).to have_link("Apple Wallet")
    end
  end
end
