# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "passes/templates/default/_show.html.haml" do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:pass) do
    Fabricate(:pass, person: person, pass_definition: definition,
      state: :eligible, valid_from: Date.new(2026, 1, 1)).decorate
  end

  before do
    assign(:group, group)
    assign(:person, person)
    assign(:pass, pass)
    assign(:pass_definition, definition)
    allow(controller).to receive(:current_user).and_return(person)
    allow(view).to receive(:current_user).and_return(person)
    allow(view).to receive(:google_wallet_configured?).and_return(false)
    allow(view).to receive(:apple_wallet_configured?).and_return(false)
    render partial: "passes/templates/default/show"
  end

  subject { Capybara::Node::Simple.new(rendered) }

  it "renders the card wrapper" do
    is_expected.to have_css(".pass-card-wrapper")
  end

  it "renders the card front" do
    is_expected.to have_css(".pass-card-front")
  end

  it "renders the card back" do
    is_expected.to have_css(".pass-card-back")
  end
end
