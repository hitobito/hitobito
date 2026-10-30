# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"
require_relative "../../db/migrate/20260827114819_event_description_as_rich_text"

RSpec.describe EventDescriptionAsRichText, type: :migration do
  subject(:migration) { described_class.new }

  describe "#rich_text_attributes" do
    def rich_text_attributes(description)
      migration.send(:rich_text_attributes, 42, description)
    end

    it "belongs to the description of the translation" do
      expect(rich_text_attributes("Beschreibung")).to include(
        record_type: "Event::Translation", record_id: 42, name: "description"
      )
    end

    it "escapes html and keeps line breaks" do
      attrs = rich_text_attributes("Erste Zeile <b>x</b> & y\r\nZweite Zeile\n\nDritte Zeile")

      expect(attrs[:body].to_html).to eq(
        "<div>Erste Zeile &lt;b&gt;x&lt;/b&gt; &amp; y<br>Zweite Zeile<br><br>Dritte Zeile</div>"
      )
      expect(attrs[:plain_text_body]).to eq("Erste Zeile <b>x</b> & y\nZweite Zeile\n\nDritte Zeile")
    end

    it "drops leading and trailing blank lines" do
      expect(rich_text_attributes("\nBeschreibung\n\n")[:body].to_html).to eq("<div>Beschreibung</div>")
    end

    it "is nil for blank descriptions" do
      expect(rich_text_attributes(" \n")).to be_nil
    end
  end
end
