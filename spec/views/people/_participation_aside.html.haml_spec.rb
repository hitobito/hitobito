# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "people/_participation_aside.html.haml" do
  let(:current_user) { people(:top_leader) }
  let(:person) { people(:bottom_member) }
  let(:participation) { event_participations(:top).decorate }
  let(:event) { participation.event }

  before do
    travel_to "2012-01-01"
    allow(controller).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:current_user).and_return(current_user)
  end

  let(:rendered) do
    render partial: "people/participation_aside",
      locals: {title: "Test Title", collection: [participation]}
  end

  subject { Capybara::Node::Simple.new(rendered) }

  it "renders the participation with event link" do
    expect(rendered).to include event.decorate.labeled_link
  end

  it "renders the participation link" do
    expect(rendered).to include event.decorate.labeled_link
  end

  describe "with single event role" do
    it "renders the participation link with single role" do
      is_expected.to have_link "Hauptleitung"
    end
  end

  describe "with multiple event roles" do
    before do
      participation.roles << Fabricate(:event_role, participation: participation, type: "Event::Role::Cook")
    end

    it "renders the participation link with multiple roles" do
      is_expected.to have_css("a", text: /Hauptleitung.*Küche/m)
    end
  end
end
