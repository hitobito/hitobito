# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "people/_passes_aside.html.haml" do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:current_user) { person }

  before do
    assign(:group, group)
    allow(controller).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:entry).and_return(person)
  end

  subject { Capybara::Node::Simple.new(rendered) }

  context "when person has no passes" do
    before do
      allow(person).to receive(:passes).and_return(
        Pass.none.tap { |r| allow(r).to receive(:includes).and_return([]) }
      )
      render partial: "people/passes_aside"
    end

    it "renders nothing" do
      expect(rendered.strip).to be_empty
    end
  end

  context "when person has passes" do
    let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
    let!(:pass) do
      Fabricate(:pass, person: person, pass_definition: definition,
        state: :eligible, valid_from: Date.current)
    end

    before do
      render partial: "people/passes_aside"
    end

    it "renders the section title" do
      is_expected.to have_css("h2", text: I18n.t("people.passes_aside.title"))
    end

    it "renders the pass definition name" do
      is_expected.to have_css("strong", text: definition.name)
    end

    it "includes a link to the show action" do
      is_expected.to have_link(definition.name)
    end
  end
end
