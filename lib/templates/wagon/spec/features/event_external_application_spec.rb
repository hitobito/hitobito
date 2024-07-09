# frozen_string_literal: true

require "spec_helper"

describe :event_external_application do
  subject { page }

  let(:event) do
    Fabricate(:event, application_opening_at: 5.days.ago,
      external_applications: true, groups: [group])
  end
  let(:group) { groups(:root) }

  it "creates an external event participation" do
    visit group_public_event_path(group_id: group, id: event)

    find_all("#new_person input#person_email").first
      .fill_in(with: "max.muster@hitobito.example.com")

    click_button("Weiter")

    fill_in "Vorname", with: "Max"
    fill_in "Nachname", with: "Muster"
    fill_in "Haupt-E-Mail", with: "max.muster@hitobito.example.com"

    expect do
      find_all('.btn-toolbar.bottom .btn-group button[type="submit"]').first.click # submit
    end.to change { Person.count }.by(1)

    fill_in("Bemerkungen", with: "Wichtige Bemerkungen über meine Teilnahme")

    expect do
      click_button("Anmelden")
    end.to change { Event::Participation.count }.by(1)

    person = Person.find_by(email: "max.muster@hitobito.example.com")
    expect(person).to be_present

    is_expected.to have_text(
      "Teilnahme von #{person.full_name} in #{event.name} wurde erfolgreich erstellt. " \
      "Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an."
    )
    is_expected.to have_text("Wichtige Bemerkungen über meine Teilnahme")
  end
end
