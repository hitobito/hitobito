# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe :event_participation, js: true do
  subject { page }

  let(:person) { people(:top_leader) }
  let(:event) { Fabricate(:event, application_opening_at: 5.days.ago, groups: [group]) }
  let(:group) { groups(:bottom_layer_one) }
  let(:participation) { Event::Participation.create!(event:, person:) }

  before do
    sign_in(person)
  end

  it "does not have option to uncheck option to send confirmation email when registering for themself" do
    visit new_group_event_participation_path(group, event)
    expect(page).not_to have_content "E-Mail an Teilnehmer/in senden"
  end

  context "event questions" do
    before do
      # create some questions
      Fabricate(:event_question, event: event, question: "Eine Frage?")
      Fabricate(:event_question, event: event, question: "A question?")
    end

    it "orders event questions by id on show page" do
      visit group_event_participation_path(group, event, participation)
      expect(find_all("section > dl > dt")[0].text).to eq "Eine Frage?"
      expect(find_all("section > dl > dt")[1].text).to eq "A question?"
    end

    it "orders event questions by id on edit page" do
      visit edit_group_event_participation_path(group, event, participation)
      expect(find_all("label.col-form-label")[0].text).to eq "Anmeldeangaben"
      expect(find_all(".fields label")[0].text).to eq "Eine Frage?"
      expect(find_all(".fields label")[1].text).to eq "A question?"
    end

    it "shows correct answers as selected on edit page for multiple choice questions" do
      Event::Question.destroy_all
      Fabricate(:event_question, event: event, question: "A question?", multiple_choices: true,
        choices: "Answer 1\\u002C with comma, Answer 2, Answer 3\\u002C with\\u002C multiple commas")
      visit group_event_path(group_id: group, id: event)
      click_link("Anmelden")
      within(".bottom .btn-group") do
        click_button("Weiter")
      end
      expect(page).to have_content("Anmeldeangaben")

      check("Answer 1, with comma")
      check("Answer 3, with, multiple commas")

      click_button("Anmelden")

      expect(page).to have_content(
                        "Teilnahme von #{person.full_name} in #{event.name} wurde erfolgreich erstellt. " \
                          "Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an."
                      )

      within(".btn-toolbar") do
        click_link("Bearbeiten")
      end

      expect(page).to have_content("Anmeldung von #{person.full_name} bearbeiten")

      Globalized.languages.each do |lang|
        click_link(lang.to_s.upcase)
        expect(page).to have_current_path(/\/#{lang}\//)
        expect(page).to have_checked_field("Answer 1, with comma")
        expect(page).to have_unchecked_field("Answer 2")
        expect(page).to have_checked_field("Answer 3, with, multiple commas")
      end
    end

    it "shows correct answers as selected on edit page for single choice questions" do
      Event::Question.destroy_all
      Fabricate(:event_question, event: event, question: "A question?",
        choices: "Answer 1\\u002C with comma, Answer 2\\u002C with\\u002C multiple commas, Answer 3")
      visit group_event_path(group_id: group, id: event)
      click_link("Anmelden")
      within(".bottom .btn-group") do
        click_button("Weiter")
      end
      expect(page).to have_content("Anmeldeangaben")

      choose("Answer 2, with, multiple commas")

      click_button("Anmelden")

      expect(page).to have_content(
                        "Teilnahme von #{person.full_name} in #{event.name} wurde erfolgreich erstellt. " \
                          "Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an."
                      )

      within(".btn-toolbar") do
        click_link("Bearbeiten")
      end

      expect(page).to have_content("Anmeldung von #{person.full_name} bearbeiten")

      Globalized.languages.each do |lang|
        click_link(lang.to_s.upcase)
        expect(page).to have_current_path(/\/#{lang}\//)
        expect(page).to have_unchecked_field("Answer 1, with comma")
        expect(page).to have_checked_field("Answer 2, with, multiple commas")
        expect(page).to have_unchecked_field("Answer 3")
      end
    end
  end

  context "with privacy policies in hierarchy" do
    let(:top_layer) { groups(:top_layer) }

    before do
      file = Rails.root.join("spec", "fixtures", "files", "images", "logo.png")
      image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, "rb"),
        filename: "logo.png",
        content_type: "image/png").signed_id
      top_layer.layer_group.update(privacy_policy: image,
        privacy_policy_title: "Privacy Policy Top Layer")
      group.update(privacy_policy: image,
        privacy_policy_title: "Additional Policies Bottom Layer")
    end

    it "creates an event participation if privacy policy is accepted" do
      visit group_event_path(group_id: group, id: event)

      click_link("Anmelden")

      is_expected.to have_content("Privacy Policy Top Layer")
      is_expected.to have_content("Additional Policies Bottom Layer")

      find("input#event_participation_contact_data_privacy_policy_accepted").click

      find_all('.bottom .btn-group button[type="submit"]').first.click # "Weiter"

      expect do
        click_button("Anmelden")
        is_expected.to have_text(
          "Teilnahme von #{person.full_name} in #{event.name} wurde erfolgreich erstellt. " \
          "Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an."
        )
      end.to change { Event::Participation.count }.by(1)

      participation = Event::Participation.find_by(event: event, participant: person)

      expect(participation).to be_present
    end

    it "can render form without passing role type" do
      visit contact_data_group_event_participations_path(group, event)
      expect(page).to be_present
    end

    it "does not create an event participation if privacy policy is not accepted" do
      visit group_event_path(group_id: group, id: event)

      click_link("Anmelden")

      is_expected.to have_content("Privacy Policy Top Layer")
      is_expected.to have_content("Additional Policies Bottom Layer")

      find("input#event_participation_contact_data_privacy_policy_accepted") # but do not click!

      find_all('.bottom .btn-group button[type="submit"]').first.click # "Weiter"

      expect(current_path).to eq(contact_data_group_event_participations_path(group, event))
    end
  end

  context "when adding participation as an admin" do
    let(:person) { people(:root) }
    let(:event) { Fabricate(:course, application_opening_at: 5.days.ago, groups: [group]) }

    before do
      # rubocop:todo Layout/LineLength
      allow_any_instance_of(Event::ParticipationsController).to receive(:current_user_interested_in_mail?).and_return(true)
      # rubocop:enable Layout/LineLength
      visit new_group_event_participation_path(group, event, for_someone_else: true)
      expect(page).to have_content "Anmeldung als Teilnehmer/-in"
      fill_in "Person", with: "Top Leader"
      expect(page).to have_content("Top Leader")
      find('ul[role="listbox"] li[role="option"]', text: "Top Leader").click
      expect(page).to have_content "E-Mail an Teilnehmer/in senden"
    end

    it "does send email to participant when send email checkbox is checked" do
      # rubocop:todo Layout/LineLength
      allow_any_instance_of(Event::ParticipationsController).to receive(:current_user_interested_in_mail?).and_return(false)
      # rubocop:enable Layout/LineLength
      expect do
        click_on "Anmelden"
        expect(page).to have_content "Teilnahme von Top Leader in Eventus wurde erfolgreich erstellt."
      end.to change { Delayed::Job.where("handler LIKE '%Event::ParticipationConfirmationJob%'").count }.by(1)
    end

    it "does not send email to participant when send email checkbox is not checked" do
      # rubocop:todo Layout/LineLength
      allow_any_instance_of(Event::ParticipationsController).to receive(:current_user_interested_in_mail?).and_return(false)
      # rubocop:enable Layout/LineLength
      uncheck "E-Mail an Teilnehmer/in senden"
      expect do
        click_on "Anmelden"
        expect(page).to have_content "Teilnahme von Top Leader in Eventus wurde erfolgreich erstellt."
      end.not_to change { Delayed::Job.where("handler LIKE '%Event::ParticipationConfirmationJob%'").count }
    end
  end
end
