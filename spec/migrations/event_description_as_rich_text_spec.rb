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

  describe "#down" do
    let(:event) { events(:top_event) }
    let!(:event_without_description) { Fabricate(:event) }

    def description_of(event)
      ActiveRecord::Base.connection.select_value(
        "SELECT description FROM event_translations WHERE event_id = #{event.id}"
      )
    end

    before do
      ActiveRecord::Migration.verbose = false
      event.update!(description: "<div>Erste <strong>Zeile</strong><br>Zweite Zeile</div>")
      migration.migrate(:down)
    end

    after do
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Base.connection.schema_cache.clear!
      Event::Translation.reset_column_information
    end

    it "writes the plain text into the description of the translation" do
      expect(description_of(event)).to eq("Erste Zeile\nZweite Zeile")
    end

    it "leaves translations without description empty" do
      expect(description_of(event_without_description)).to be_nil
    end

    it "removes the event descriptions" do
      expect(ActionText::RichText.where(record_type: "Event::Translation")).not_to exist
    end

    it "keeps other rich texts" do
      expect(ActionText::RichText.where(id: action_text_rich_texts(:login_de_body).id)).to exist
    end
  end
end
