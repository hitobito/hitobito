# frozen_string_literal: true

#  Copyright (c) 2023-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Participation::Specifics do
  include PdfHelpers

  let(:pdf) { Export::Pdf::Document.new(page_size: "A4", page_layout: :portrait, margin: 2.cm).pdf }
  let(:event_date) do
    Event::Date.new(
      start_at: 1.week.from_now,
      finish_at: 2.weeks.from_now,
      label: "Kennenlernen",
      location: "Ferieninsel"
    )
  end
  let(:event) do
    Fabricate(:course, cost: "42 Stutz", dates: [event_date])
  end
  let(:person) do
    Fabricate(
      :person_with_address,
      phone_numbers: [Fabricate.build(:phone_number, label: "Mobil")],
      company_name: Faker::Company.name,
      email: "dude@example.com"
    )
  end
  let(:participation) { Event::Participation.create(event: event, person: person) }
  let!(:question1) { Event::Question.create!(question: "B", disclosure: :optional, event: event) }
  let!(:question2) { Event::Question.create!(question: "A", disclosure: :optional, event: event) }
  let!(:answer1) { Event::Answer.find_or_create_by(question: question1, participation: participation).update(answer: "answer b") }
  let!(:answer2) { Event::Answer.find_or_create_by(question: question2, participation: participation).update(answer: "answer a") }

  context "with questions set to sort by id (by default)" do
    it "renders correctly" do
      described_class.new(pdf, participation).render

      expect(text_with_position.pretty_inspect).to eq [
        [57, 773, "Anmeldeangaben"],
        [59, 747, "B"],
        [69, 747, "answer b"],
        [59, 731, "A"],
        [69, 731, "answer a"],
        [57, 696, "Bemerkungen"],
        [57, 673, "-"]
      ].pretty_inspect
    end
  end

  context "with questions set to sort by id (by default)" do
    around do |example|
      original = Event::Question.sort_alphabetically
      Event::Question.sort_alphabetically = true
      example.run
      Event::Question.sort_alphabetically = original
    end

    it "renders correctly" do
      described_class.new(pdf, participation).render

      expect(text_with_position.pretty_inspect).to eq [
        [57, 773, "Anmeldeangaben"],
        [59, 747, "A"],
        [69, 747, "answer a"],
        [59, 731, "B"],
        [69, 731, "answer b"],
        [57, 696, "Bemerkungen"],
        [57, 673, "-"]
      ].pretty_inspect
    end
  end
end
