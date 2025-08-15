require "spec_helper"

describe :event_external_application do
  subject { page }

  let(:event) {
    Fabricate(:event, application_opening_at: 5.days.ago,
      external_applications: true, groups: [group])
  }
  let(:group) { groups(:top_layer) }

  def fill_in_form
    within ".row article:nth-of-type(2)" do
      fill_in "Haupt-E-Mail", with: "max.muster@hitobito.example.com"
      click_button("Weiter")
    end

    fill_in "Vorname", with: "Max"
    fill_in "Nachname", with: "Muster"
    fill_in "Haupt-E-Mail", with: "max.muster@hitobito.example.com"
  end

  it "creates an external event participation" do
    visit group_public_event_path(group_id: group, id: event)

    fill_in_form

    expect do
      find_all('.bottom .btn-group button[type="submit"]').first.click # submit
      is_expected.to have_text("Anmeldung als Teilnehmer/-in")
    end.to change { Person.count }.by(1)

    fill_in("Bemerkungen", with: "Wichtige Bemerkungen über meine Teilnahme")

    expect do
      click_button("Anmelden")
      # rubocop:todo Layout/LineLength
      is_expected.to have_text("Teilnahme von Max Muster in #{event.name} wurde erfolgreich erstellt. Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an.")
      # rubocop:enable Layout/LineLength
      is_expected.to have_text("Wichtige Bemerkungen über meine Teilnahme")
    end.to change { Event::Participation.count }.by(1)
  end

  it "orders event questions by id in event signup form" do
    Fabricate(:event_question, event: event, question: "Eine Frage?")
    Fabricate(:event_question, event: event, question: "A question?")
    visit group_public_event_path(group_id: group, id: event)
    fill_in_form
    find_all('.bottom .btn-group button[type="submit"]').first.click # submit
    expect(find("#event_participation_answers_attributes_0_question_id+div > label").text).to eq "Eine Frage?"
    expect(find("#event_participation_answers_attributes_1_question_id+div > label").text).to eq "A question?"
  end
end
