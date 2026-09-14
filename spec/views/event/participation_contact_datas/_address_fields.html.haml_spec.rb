#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/participation_contact_datas/_address_fields.html.haml" do
  let(:event) { Fabricate(:event, hidden_contact_attrs: ["street", "housenumber"]).decorate }
  let(:group) { Fabricate(:group, type: "Group::TopLayer").decorate }
  let(:participation_contact_data) { Event::ParticipationContactData.new(event, people(:top_leader), {}) }

  before do
    allow(view).to receive(:f).and_return(StandardFormBuilder.new(:entry, participation_contact_data, view, {}))
  end

  [:address_care_of, :postbox, :zip_code, :town, :country].each do |attribute|
    it "does not render input with id entry_#{attribute} when attribute is hidden" do
      event.update!(hidden_contact_attrs: [attribute])
      render locals: {entry: participation_contact_data, event:, group:}
      expect(rendered).not_to have_selector("input#entry_#{attribute}")
    end
  end

  describe "street and housenumber" do
    it "does not render either if both are hidden" do
      event.update!(hidden_contact_attrs: [:street, :housenumber])
      render locals: {entry: participation_contact_data, event:, group:}
      expect(rendered).not_to have_selector("input#entry_street")
      expect(rendered).not_to have_selector("input#entry_housenumber")
    end

    it "does render both if only street is hidden" do
      event.update!(hidden_contact_attrs: [:housenumber])
      render locals: {entry: participation_contact_data, event:, group:}
      expect(rendered).to have_selector("input#entry_street")
      expect(rendered).to have_selector("input#entry_housenumber")
    end

    it "does render both if only housenumber is hidden" do
      event.update!(hidden_contact_attrs: [:housenumber])
      render locals: {entry: participation_contact_data, event:, group:}
      expect(rendered).to have_selector("input#entry_street")
      expect(rendered).to have_selector("input#entry_housenumber")
    end
  end

  it "should render address label when only housenumber is hidden" do
    event.update!(hidden_contact_attrs: [:housenumber])
    render locals: {entry: participation_contact_data, event:, group:}
    expect(rendered).to have_text("Strasse")
    expect(rendered).to have_text("Nr.")
  end

  it "should not render address label if no address attributes are set to display" do
    event.update!(hidden_contact_attrs: [:housenumber, :street])
    render locals: {entry: participation_contact_data, event:, group:}
    expect(rendered).to have_no_text("Strasse")
    expect(rendered).to have_no_text("Nr.")
  end

  describe "canton" do
    it "renders canton select inside a hidden container when country is not Switzerland" do
      render locals: {entry: participation_contact_data, event:, group:}
      expect(rendered).to have_selector(
        "[data-field-visibility-target='container'].hidden select#entry_canton"
      )
    end

    it "renders canton select inside a visible container when country is Switzerland" do
      people(:top_leader).country = "CH"
      render locals: {entry: participation_contact_data, event:, group:}
      expect(rendered).to have_selector(
        "[data-field-visibility-target='container'] select#entry_canton"
      )
      expect(rendered).not_to have_selector(
        "[data-field-visibility-target='container'].hidden select#entry_canton"
      )
    end

    it "does not render canton select when country is hidden for the event" do
      event.update!(hidden_contact_attrs: [:country])
      render locals: {entry: participation_contact_data, event:, group:}
      expect(rendered).not_to have_selector("select#entry_canton")
    end

    it "does not render canton select when canton setting is disabled" do
      allow(Settings.people).to receive(:canton).and_return(false)
      render locals: {entry: participation_contact_data, event:, group:}
      expect(rendered).not_to have_selector("select#entry_canton")
    end

    it "does not raise when rendered for an Event::Guest" do
      guest = Event::Guest.new(first_name: "Guest", last_name: "Person", country: "CH")
      allow(view).to receive(:f).and_return(StandardFormBuilder.new(:entry, guest, view, {}))

      expect { render locals: {entry: guest, event:, group:} }.not_to raise_error
      expect(rendered).not_to have_selector("select#entry_canton")
    end
  end
end
