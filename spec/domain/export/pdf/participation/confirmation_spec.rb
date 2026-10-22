# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Participation::Confirmation do
  include PdfHelpers

  let(:pdf) { Export::Pdf::Document.new(page_size: "A4", page_layout: :portrait, margin: 2.cm).pdf }
  let(:contact) do
    Fabricate(:person, first_name: "Kurt", last_name: "Kontakt", email: "kurt@example.com",
      street: "Kontaktweg", housenumber: "3", zip_code: "3000", town: "Bern")
  end
  let(:event) { Fabricate(:course, contact: contact) }
  let(:application) { Fabricate(:event_application, priority_1: event, priority_2: nil) }
  let(:participation) do
    Fabricate(:event_participation, event: event, application: application)
  end

  def rendered_text
    described_class.new(pdf, participation).render
    text_with_position.map(&:last)
  end

  it "renders name, address and email of the contact" do
    expect(rendered_text).to eq [
      "Anmeldung an",
      "Kurt Kontakt, Kontaktweg 3, 3000 Bern oder kurt@example.com"
    ]
  end

  it "omits the address when it is not visible" do
    event.update!(visible_contact_attributes: %w[name email])

    expect(rendered_text).to eq ["Anmeldung an", "Kurt Kontakt oder kurt@example.com"]
  end

  it "omits the email when it is not visible" do
    event.update!(visible_contact_attributes: %w[name address])

    expect(rendered_text).to eq ["Anmeldung an", "Kurt Kontakt, Kontaktweg 3, 3000 Bern"]
  end

  it "omits the name when it is not visible" do
    event.update!(visible_contact_attributes: %w[address email])

    expect(rendered_text).to eq ["Anmeldung an", "Kontaktweg 3, 3000 Bern oder kurt@example.com"]
  end

  it "does not end with oder when the contact has no email" do
    contact.update_columns(email: nil)

    expect(rendered_text).to eq ["Anmeldung an", "Kurt Kontakt, Kontaktweg 3, 3000 Bern"]
  end

  it "renders only the email when name and address are not visible" do
    event.update!(visible_contact_attributes: %w[email])

    expect(rendered_text).to eq ["Anmeldung an", "kurt@example.com"]
  end

  it "omits the section when none of name, address and email is visible" do
    event.update!(visible_contact_attributes: %w[phone_number])

    expect(rendered_text).to be_empty
  end

  it "omits the section when the event has no contact" do
    event.update!(contact: nil)

    expect(rendered_text).to be_empty
  end
end
