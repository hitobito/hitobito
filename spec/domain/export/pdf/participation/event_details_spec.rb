# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Participation::EventDetails do
  let(:pdf) { Export::Pdf::Document.new(page_size: "A4", page_layout: :portrait, margin: 2.cm).pdf }
  let(:event) { events(:top_event) }
  let(:participation) { Event::Participation.new(event: event, person: people(:top_leader)) }

  let(:rendered) do
    described_class.new(pdf, participation).render
    pdf.render
  end
  let(:text) { PDF::Inspector::Text.analyze(rendered) }

  before do
    event.update!(description: "<div>Erste Zeile<br><strong>Zweite</strong> Zeile</div>" \
      "<ul><li>Punkt</li></ul><div>Mehr auf https://example.com</div>")
  end

  it "renders the formatted description" do
    expect(text.strings).to include("Erste Zeile", "Zweite", " Zeile", "•", "Punkt")
    expect(text.font_settings.map { _1[:name].to_s }).to include(end_with("Bold"))
  end

  it "links urls in the description" do
    expect(text.strings).to include("https://example.com")
    expect(rendered).to include("/URI (https://example.com)")
  end
end
