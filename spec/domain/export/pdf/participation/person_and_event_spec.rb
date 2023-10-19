# frozen_string_literal: true

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Pdf::Participation::PersonAndEvent do
  include PdfHelpers

  let(:pdf) { Prawn::Document.new(page_size: 'A4', page_layout: :portrait, margin: 2.cm) }
  let(:event_date) do
    Event::Date.new(
        start_at: 1.week.from_now,
        finish_at: 2.weeks.from_now,
        label: 'Kennenlernen',
        location: 'Ferieninsel'
      )
  end
  let(:event) do
    Fabricate(:course, cost: '42 Stutz', dates: [event_date])
  end
  let(:person) do
    Fabricate(:person_with_address, phone_numbers: [
      Fabricate.build(:phone_number, label: 'Mobil')
    ], company_name: Faker::Company.name,
    email: 'dude@example.com'
             )
  end
  let(:participation) { Event::Participation.create(event: event, person: person) }

  it 'renders correctly' do
    described_class.new(pdf, participation).render

    expect(text_with_position.pretty_inspect).to eq [
      [57, 777, "Teilnehmer/-in"],
      [303, 777, "Kurs"],
      [57, 753, person.person_name],
      [57, 739, person.address],
      [57, 725, "#{person.zip_code} #{person.town}"],
      [57, 701, person.phone_numbers.first.to_s],
      [57, 688, person.email],
      [303, 753, event.name],
      [303, 729, event.number],
      [303, 715, "SLK (Scharleiterkurs)"],
      [303, 701, "Kosten: #{event.cost}"],
      [303, 678, "Daten"],
      [303, 663, event_date.label_and_location],
      [303, 649, event_date.duration.to_s]
    ].pretty_inspect
  end
end
