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
      ahv_number: Event::Question::AhvNumber.create!(question: "AHV-Number?", event_type: nil, disclosure: nil),
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

  describe "global application_questions" do
    subject(:question_fields_element) do
      click_link I18n.t("event.participations.application_answers")
      page.find("#application_questions_fields")
    end

    before do
      Event::Question.delete_all
      global_questions
      sign_in
      visit edit_group_event_path(event.group_ids.first, event.id)
    end

    it "includes global questions with matching event type" do
      is_expected.to have_text(global_questions[:ahv_number].question)
      is_expected.to have_text(global_questions[:vegetarian].question)
      is_expected.not_to have_text(global_questions[:camp_only].question)
      is_expected.to have_text(global_questions[:hidden].question)
    end

    it "requires questions to have disclosure selected before saving" do
      click_save
      expect(page).to have_content("Anmeldeangaben ist nicht gültig")

      question_fields_element.all(".fields").find_each do |question_element|
        within(question_element) do
          choose(Event::Question.disclosure_labels[:optional])
        end
      end
      click_save
      expect(page).to have_content "Anlass Eventus wurde erfolgreich aktualisiert."
    end
  end

  describe "answers for global questions" do
    let(:event_with_questions) do
      event.init_questions
      event.application_questions.map { |question| question.update!(disclosure: question.disclosure || :optional) }
      event.save!
      event
    end

    subject { page }

    before do
      Event::Question.delete_all
      global_questions
      event_with_questions
      sign_in
      visit contact_data_group_event_participations_path(event.group_ids.first, event.id, event_role: {type: Event::Role::Participant})
      click_next
    end

    it "hides hidden questions but shows others" do
      is_expected.to have_text(global_questions[:ahv_number].question)
      is_expected.to have_text(global_questions[:vegetarian].question)
      is_expected.to have_text(global_questions[:required].question + " *")

      is_expected.not_to have_text(global_questions[:camp_only].question)
      is_expected.not_to have_text(global_questions[:hidden].question)
    end

    it "saves only valid data" do
      sleep 0.5 # avoid wizard race condition
      page.all(".bottom .btn-group").first.click_button "Anmelden"

      all(".fields").each do |question_element|
        within(question_element) do
          puts question_element.text
        end
      end

      is_expected.to have_content "Teilnahme von Top Leader in Eventus wurde erfolgreich erstellt."
    end
  end

  describe Event::Answer do
    let(:question) { event_questions(:top_ov) }
    let(:choices) { question.choices.split(",") }

    context "answer= for array values (checkboxes)" do
      subject { question.reload.answers.build }

      before do
        question.update_attribute(:multiple_choices, true) # rubocop:disable Rails/SkipsModelValidations
        subject.answer = answer_param
        subject.save
      end

      context "valid array values (position + 1)" do
        let(:answer_param) { %w[1 2] }

        its(:answer) { is_expected.to eq "GA, Halbtax" }
        it { is_expected.to have(0).errors_on(:answer) }
      end

      context "values outside of array size" do
        let(:answer_param) { %w[4 5] }

        its(:answer) { is_expected.to be_nil }
      end

      context "resetting values" do
        subject { question.reload.answers.create(answer: "GA, Halbtax") }

        let(:answer_param) { ["0"] }

        its(:answer) { is_expected.to be_nil }
      end
    end

    context "validates answers to single-answer questions correctly: " do
      describe "a non-required question" do
        let(:question) { Fabricate(:event_question, disclosure: :optional, choices: "Ja") }

        subject(:no_answer_given) { build_answer("0") } # no choice

        subject(:yes_answer) { build_answer("1") }
        subject(:depends_answer) { build_answer("2") } # not a valid choice

        it "may be left unanswered" do
          expect(no_answer_given).to have(0).errors_on(:answer)
        end

        it "may be answered with the one option" do
          expect(yes_answer).to have(0).errors_on(:answer)
        end

        it "may not be answered with something else" do
          expect(depends_answer.answer).to be_nil
        end

        def build_answer(answer_index)
          question.answers.create(answer: [answer_index])
        end
      end
    end
  end
end
