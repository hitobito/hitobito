# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe EventsController, js: true do
  let(:event) do
    Fabricate(:event, groups: [groups(:top_group)]).tap do |event|
      event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    end
  end

  describe "global application_questions" do
    let(:global_questions) do
      {
        ahv_number: Event::Question::AhvNumber.create(question: 'AHV-Number?', event_type: nil ),
        vegetarian: Event::Question::Default.create(question: 'Vegetarian?', choices: 'yes', event_type: 'Event'),
        camp_only: Event::Question::Default.create(question: 'Course?', event_type: 'Event::Camp'),
        hidden: Event::Question::Default.create(question: 'Hidden?', disclosure: :hidden)
      }
    end

    def click_save
      all("form .btn-group").first.click_button "Speichern"
    end

    before do
      global_questions
      sign_in
      visit edit_group_event_path(event.group_ids.first, event.id)
      click_link I18n.t('event.participations.application_answers')
    end

    it "includes global questions with matching event type" do
      question_fields = page.find("#application_questions_fields")

      expect(question_fields).to have_text(global_questions[:ahv_number].question)
      expect(question_fields).to have_text(global_questions[:vegetarian].question)
      expect(question_fields).not_to have_text(global_questions[:camp_only].question)
      expect(question_fields).to have_text(global_questions[:hidden].question)
    end

    it "requires questions to have disclosure selected before saving" do
      click_save
      expect(page).to have_content("Anmeldeangaben ist nicht gültig")


    end

  end
  # 3. sollte keine änderungen an der Frage erlauben

  #   let(:edit_path) {  }
  #

  #   it "may set and remove contact from event" do
  #     obsolete_node_safe do
  #       sign_in
  #       visit edit_path

  #       notification_checkbox_visible(false)

  #       # set contact
  #       fill_in "Kontaktperson", with: "Top"
  #       expect(find('ul[role="listbox"] li[role="option"]')).to have_content "Top Leader"
  #       find('ul[role="listbox"] li[role="option"]').click
  #       find("body").send_keys(:tab) # unfocus input field
  #       notification_checkbox_visible(true)
  #       click_save

  #       # show event
  #       expect(find("aside")).to have_content "Kontakt"
  #       expect(find("aside")).to have_content "Top Leader"
  #       click_link "Bearbeiten"
  #       notification_checkbox_visible(true)

  #       # remove contact
  #       expect(find("#event_contact").value).to eq("Top Leader")
  #       fill_in "Kontaktperson", with: ""
  #       notification_checkbox_visible(false)
  #       click_save

  #       # show event again
  #       expect(page).to have_no_selector(".contactable")
  #     end

  #   it "toggles participation notifications" do
  #     event.update(contact: people(:top_leader))

  #     sign_in
  #     visit edit_path

  #     expect(notification_checkbox).not_to be_checked
  #     notification_checkbox.click
  #     click_save

  #     visit edit_path
  #     expect(notification_checkbox).to be_checked
  #   end
  # end

  # context "standard course description gets updated from event kind" do
  #   let(:form_path) { new_group_event_path(event.group_ids.first, event.id, event: {type: Event::Course}, format: :html) }
  #   let(:prefill_description) { "Test description" }

  #   before do
  #     sign_in
  #     visit form_path
  #   end

  #   it "fills default description if empty" do
  #     obsolete_node_safe do
  #       select "SLK (Scharleiterkurs)", from: "event_kind_id"
  #       expect(find("#event_description").value).to eq event.kind.general_information
  #     end
  #   end

  #   it "does not fill textarea" do
  #     obsolete_node_safe do
  #       fill_in "event_description", with: prefill_description
  #       select "SLK (Scharleiterkurs)", from: "event_kind_id"
  #       expect(find("#event_description").value).to eq prefill_description
  #     end
  #   end
  # end
end
