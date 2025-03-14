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
  let(:global_questions) do
    {
      vegetarian: Event::Question::Default.create!(question: "Vegetarian?", choices: "yes", event_type: "Event"),
      camp_only: Event::Question::Default.create!(question: "Course?", event_type: "Event::Camp"),
      required: Event::Question::Default.create!(question: "Required?", disclosure: :required),
      hidden: Event::Question::Default.create!(question: "Hidden?", disclosure: :hidden)
    }
  end

  def click_save
    all("form .btn-group").first.click_button "Speichern"
  end

  def click_next
    find_all(".bottom .btn-group").first.click_button "Weiter"
  end

  def click_signup
    all(".bottom .btn-group").first.click_button "Anmelden"
  end

  def find_question_field(question)
    page.all(".fields").find { |question_element| question_element.text.start_with?(question.question) }
  end

  describe "global application_questions" do
    subject(:question_fields_element) do
      click_link I18n.t("event.participations.application_answers")
      page.find("#application_questions_fields")
    end

    before do
      Event::Question.delete_all
      global_questions
      sign_in
    end

    it "includes global questions with matching event type" do
      visit edit_group_event_path(event.group_ids.first, event.id)
      is_expected.to have_text(global_questions[:vegetarian].question)
      is_expected.not_to have_text(global_questions[:camp_only].question)
      is_expected.to have_text(global_questions[:hidden].question)

      is_expected.not_to have_text("Entfernen")
    end

    it "includes global questions with matching event type" do
      visit edit_group_event_path(event.group_ids.first, event.id)
      click_save
      expect(page).to have_content "Anlass Eventus wurde erfolgreich aktualisiert."
    end

    it "requires questions to have disclosure selected before saving" do
      visit new_group_event_path(groups(:top_group))
      fill_in(:event_name, with: "Eventus2")
      click_on("Daten")
      fill_in(:event_dates_attributes_0_start_at_date, with: "01.01.2025")
      click_save
      expect(page).to have_content("Registration information is not valid")

      question_fields_element.all(".fields").each do |question_element| # rubocop:disable Rails/FindEach
        within(question_element) do
          choose(Event::Question.disclosure_labels[:optional])
        end
      end
      click_save
      expect(page).to have_content "Anlass Eventus2 wurde erfolgreich erstellt."
    end
  end

  describe "answers for global questions" do
    let(:event_with_questions) do
      event.init_questions
      event.application_questions.map { |question| question.update!(disclosure: question.disclosure || :optional) }
      event.save!
      event
    end
    let(:user) { people(:bottom_member) }

    subject { page }

    before do
      Event::Question.delete_all
      global_questions
      event_with_questions
      sign_in(user)
      visit contact_data_group_event_participations_path(event.group_ids.first, event.id,
        event_role: {type: Event::Role::Participant})
      click_next
    end

    it "hides hidden questions but shows others" do
      is_expected.to have_text(global_questions[:vegetarian].question)
      is_expected.to have_text(global_questions[:required].question + " *")

      is_expected.not_to have_text(global_questions[:camp_only].question)
      is_expected.not_to have_text(global_questions[:hidden].question)
    end

    it "fails with empty required questions" do
      sleep 1 # avoid wizard race condition
      click_signup

      is_expected.to have_content "Antwort muss ausgefüllt werden"

      within find_question_field(global_questions[:required]) do
        answer_element = find('input[type="text"]')
        answer_element.fill_in(with: "Something")
      end

      click_signup
      is_expected.to have_content "Teilnahme von Bottom Member in Eventus wurde erfolgreich erstellt."
    end
  end
end
