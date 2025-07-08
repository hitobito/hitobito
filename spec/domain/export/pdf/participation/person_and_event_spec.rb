# frozen_string_literal: true

#  Copyright (c) 2023-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Participation::PersonAndEvent do
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

  it "renders correctly" do
    described_class.new(pdf, participation).render

    expect(text_with_position.pretty_inspect).to eq [
      [57, 773, "Teilnehmer/-in"],
      [301, 773, "Kurs"],
      [57, 751, person.person_name],
      [57, 738, person.address],
      [57, 726, "#{person.zip_code} #{person.town}"],
      [57, 704, person.phone_numbers.first.to_s],
      [57, 692, person.email],
      [301, 751, event.name],
      [301, 728, event.number],
      [301, 716, "SLK (Scharleiterkurs)"],
      [301, 704, "Kosten: #{event.cost}"],
      [301, 682, "Daten"],
      [301, 669, event_date.label_and_location],
      [301, 657, event_date.duration.to_s]
    ].pretty_inspect
  end

  context "given a date with wider characters correctly, it" do
    let(:event_date) do
      Event::Date.new(
        start_at: DateTime.parse("2044-04-04 14:44"),
        finish_at: DateTime.parse("2044-04-24 14:44")
      )
    end

    it "renders correctly" do
      described_class.new(pdf, participation).render

      expect(text_with_position).to include [301, 657, event_date.duration.to_s]
    end
  end
end
