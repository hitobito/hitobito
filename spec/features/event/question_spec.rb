# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
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
  let(:question_templates) do
    {
      vegetarian: Event::QuestionTemplate.create!(
        group: groups(:top_layer),
        default: true,
        event_type: "Event",
        question: Event::Question::Default.create!(question: "Vegetarian?", choices: "yes")
      ),
      camp_only: Event::QuestionTemplate.create!(
        group: groups(:top_layer),
        default: true,
        event_type: "Event::Camp",
        question: Event::Question::Default.create!(question: "Course?")
      ),
      required: Event::QuestionTemplate.create!(
        group: groups(:top_layer),
        default: true,
        question: Event::Question::Default.create!(question: "Required?", required: true)
      )
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

  def add_question_with_choices(question_text:, required:, multiple_choices:, choices:)
    within("#application_questions") do
      click_link I18n.t("global.associations.add")
    end

    within(all(".fields[data-new-record='true']").last) do
      fill_in "Frage", with: question_text
      check "Obligatorisch" if required

      multiple_choices ? check("Mehrfachauswahl") : uncheck("Mehrfachauswahl")

      choices.each do |choice_text|
        click_link I18n.t("event.questions.add_choice")
        all("input[name*='[choice]']").last.set(choice_text)
      end
    end
  end

  def setup_test_questions
    # Navigate to application questions tab
    click_link I18n.t("event.participations.application_answers")

    # Add all test questions
    test_questions.each do |question_data|
      add_question_with_choices(**question_data)
    end
  end

  def verify_all_questions_present
    click_link I18n.t("event.participations.application_answers")
    expect(page).to have_text(I18n.t("events.form.explain_application_questions"))

    test_questions.each do |question_data|
      verify_question(question_data)
    end
  end

  def verify_question(question_data)
    question_fields = find_field("Frage", with: question_data[:question_text]).ancestor(".fields")
    within(question_fields) do
      verify_question_options(question_data)
      verify_choices(question_data[:choices])
    end
  end

  def verify_question_options(question_data)
    expect(page).to have_field("Obligatorisch", checked: question_data[:required])
    if question_data[:multiple_choices]
      expect(page).to have_checked_field("Mehrfachauswahl")
    else
      expect(page).to have_unchecked_field("Mehrfachauswahl")
    end
  end

  def verify_choices(choices)
    choices.each do |expected_choice|
      expect(page).to have_field("Antwortmöglichkeit", with: expected_choice)
    end
  end

  describe "application_questions" do
    let(:test_questions) do
      [
        {
          question_text: "Question 1 - Optional Single",
          required: false,
          multiple_choices: false,
          choices: ["Q1 Choice 1", "Q1 Choice 2"]
        },
        {
          question_text: "Question 2 - Required Multiple",
          required: true,
          multiple_choices: true,
          choices: ["Q2 Choice 1", "Q2 Choice 2", "Q2 Choice 3"]
        },
        {
          question_text: "Question 3 - Optional Free Text",
          required: true,
          multiple_choices: false,
          choices: []
        }
      ]
    end

    before do
      Settings.event.participations.delete_answers_after_months = 6
      Settings.event.participations.manual_sensitive_option = true
      Event::Question.delete_all
      sign_in
    end

    it "should preserve all questions with options and choices when validation fails" do
      visit new_group_event_path(groups(:top_layer).id, event: {type: "Event::Course"})

      setup_test_questions

      # Submit without required fields (will fail validation)
      click_save
      expect(page).to have_text("muss ausgefüllt werden")

      verify_all_questions_present
    end

    it "should save all questions with options and choices" do
      visit new_group_event_path(groups(:top_layer).id, event: {type: "Event::Course"})

      # Fill in required event fields
      fill_in :event_name, with: "Test Event"
      fill_in "Beschreibung", with: "Test Description"
      select "SLK", from: "Kursart"

      # Navigate to dates tab and add a date
      click_link I18n.t("activerecord.models.event/date.other")
      fill_in :event_dates_attributes_0_start_at_date, with: 10.days.from_now.strftime("%d.%m.%Y")

      setup_test_questions

      # Save the event
      click_save

      # Verify event was created
      expect(page).to have_text("Test Event")

      # Edit the event to verify all questions and choices were saved
      click_link I18n.t("global.link.edit")
      click_link I18n.t("event.participations.application_answers")

      verify_all_questions_present
    end

    it "should show all choices when editing an existing event with translated choices" do
      event.questions.create!(
        question: "Testquestion",
        choices_de: "Antwort 1,Antwort 2,Antwort 3",
        choices_en: "Choice 1,Choice 2,Choice 3",
        choices_fr: "Réponse 1,Réponse 2,Réponse 3",
        choices_it: "Risposta 1,Risposta 2,Risposta 3",
        required: true
      )

      visit edit_group_event_path(event.group_ids.first, event.id)
      click_link I18n.t("event.participations.application_answers")

      # Verify all 3 choices are rendered in the form
      expect(page).to have_field("Antwortmöglichkeit", with: "Antwort 1")
      expect(page).to have_field("Antwortmöglichkeit", with: "Antwort 2")
      expect(page).to have_field("Antwortmöglichkeit", with: "Antwort 3")

      # Count only the choice fields (inside #choices_fields, not the parent question field)
      choice_fields = page.all("#choices_fields > .fields", visible: true)
      expect(choice_fields.count).to eq(3)
    end

    it "should show choices as nested_form" do
      event_question = event.questions.create!(
        question: "Testquestion",
        choices: "Antwort 1, Antwort 2",
        choices_en: "Choice 1, Choice 2",
        required: true
      )

      visit edit_group_event_path(event.group_ids.first, event.id)
      click_link I18n.t("event.participations.application_answers")

      expect(page).to have_field("Antwortmöglichkeit", with: "Antwort 1")
      expect(page).to have_field("Antwortmöglichkeit", with: "Antwort 2")

      all(".fa-language")[1].click

      expect(page).to have_field(
        "event[application_questions_attributes][0][choices_attributes][0][choice_en]",
        with: "Choice 1"
      )
      fill_in(
        "event[application_questions_attributes][0][choices_attributes][0][choice_fr]",
        with: "Résponse 1"
      )

      click_link("Antwortmöglichkeit hinzufügen")
      expect(page).to have_content("Antwortmöglichkeit", count: 5)
      expect(page).to have_field("Sensibel")
      expect(page).to have_field("Obligatorisch")

      all(".fa-language").last.click
      input_id = all(".fields").last.first("input")[:id]
      fill_in(input_id, with: "New choice")

      first(:button, "Speichern").click
      expect(page).to have_content("Anlass #{event.name} wurde erfolgreich aktualisiert")

      choices = event_question.reload.deserialized_choices
      expect(choices.count).to eql(3)
      expect(choices.first.choice_translations).to eql({de: "Antwort 1", en: "Choice 1", fr: "Résponse 1", it: ""})
      expect(choices.second.choice_translations).to eql({de: "Antwort 2", en: "Choice 2", fr: "", it: ""})
      expect(choices.third.choice_translations).to eql({de: "New choice", en: "", fr: "", it: ""})
    end

    it "should not have sensitive checkbox when manual_sensitive_option is disabled" do
      Settings.event.participations.manual_sensitive_option = false

      expect(page).not_to have_field "Sensibel"
    end
  end

  describe "global application_questions" do
    subject(:question_fields_element) do
      click_link I18n.t("event.participations.application_answers")
      page.find("#application_questions_fields")
    end

    before do
      Event::QuestionTemplate.delete_all
      question_templates
      event.init_questions
      event.save!
      sign_in
    end

    it "includes global questions with matching event type" do
      visit edit_group_event_path(event.group_ids.first, event.id)
      is_expected.to have_text(question_templates[:vegetarian].question.question)
      is_expected.not_to have_text(question_templates[:camp_only].question.question)

      is_expected.not_to have_text("Entfernen")
    end

    it "includes global questions with matching event type" do
      visit edit_group_event_path(event.group_ids.first, event.id)
      click_save
      expect(page).to have_content "Anlass Eventus wurde erfolgreich aktualisiert."
    end
  end

  describe "answers for global questions" do
    let(:event_with_questions) do
      event.init_questions
      event.application_questions.map { |question| question.update!(required: question.required || false) }
      event.save!
      event
    end
    let(:user) { people(:bottom_member) }

    subject { page }

    before do
      Event::QuestionTemplate.delete_all
      question_templates
      event_with_questions
      sign_in(user)
      visit contact_data_group_event_participations_path(event.group_ids.first, event.id,
        event_role: {type: Event::Role::Participant})
      click_next
    end

    it "hides hidden questions but shows others" do
      is_expected.to have_text(question_templates[:vegetarian].question.question)
      is_expected.to have_text(question_templates[:required].question.question + " *")

      is_expected.not_to have_text(question_templates[:camp_only].question.question)
    end

    it "fails with empty required questions" do
      sleep 1 # avoid wizard race condition
      click_signup

      is_expected.to have_content "Antwort muss ausgefüllt werden"

      within find_question_field(question_templates[:required].question) do
        answer_element = find('input[type="text"]')
        answer_element.fill_in(with: "Something")
      end

      click_signup
      is_expected.to have_content "Teilnahme von Bottom Member in Eventus wurde erfolgreich erstellt."
    end
  end
end
