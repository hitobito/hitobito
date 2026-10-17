# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/participations/_apply_to.html.haml" do
  let(:contact) do
    Fabricate(:person, first_name: "Kurt", last_name: "Kontakt", email: "kurt@example.com",
      street: "Kontaktweg", housenumber: "3", zip_code: "3000", town: "Bern")
  end
  let(:event) { Fabricate(:course, groups: [groups(:top_layer)], contact: contact) }
  let(:application) { Fabricate(:event_application, priority_1: event, priority_2: nil) }
  let(:participation) do
    Fabricate(:event_participation, event: event, application: application)
  end

  subject(:dom) do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    Fabricate(:phone_number, contactable: contact, number: "+41 31 123 45 67", public: true)
    assign(:application, Event::ApplicationDecorator.decorate(application))
    allow(view).to receive_messages(entry: participation.decorate)
    allow(view).to receive_messages(current_user: participation.person)
  end

  it "renders all contact attributes by default" do
    expect(dom).to have_text "Anmeldung an"
    expect(dom).to have_text "Kurt Kontakt"
    expect(dom).to have_text "Kontaktweg 3"
    expect(dom).to have_text "kurt@example.com"
    expect(dom).to have_text "+41 31 123 45 67"
  end

  it "renders only visible contact attributes" do
    event.update!(visible_contact_attributes: %w[name email])

    expect(dom).to have_text "Kurt Kontakt"
    expect(dom).to have_text "kurt@example.com"
    expect(dom).not_to have_text "Kontaktweg 3"
    expect(dom).not_to have_text "+41 31 123 45 67"
  end

  it "renders nothing when no contact attribute is visible" do
    event.update!(visible_contact_attributes: [])

    expect(dom).not_to have_text "Anmeldung an"
  end

  it "renders nothing for other people than the participant" do
    allow(view).to receive_messages(current_user: people(:top_leader))

    expect(dom).not_to have_text "Anmeldung an"
  end
end
