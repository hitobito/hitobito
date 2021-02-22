#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::EventsExportJob do
  subject { Export::EventsExportJob.new(format, user.id, group.id, event_filter.to_h, filename: "event_export") }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:year) { 2012 }
  let(:event_filter) { Event::Filter.new(group, nil, "all", year, false) }
  let(:filepath) { AsyncDownloadFile::DIRECTORY.join("event_export") }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]
    Fabricate(:event)
  end

  context "creates a CSV-Export" do
    let(:format) { :csv }

    it "and saves it" do
      subject.perform

      lines = File.readlines("#{filepath}.#{format}")
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Name;Organisatoren;Beschreibung;.*/)
      expect(lines[0].split(";").count).to match(34)
    end
  end

  context "creates an Excel-Export" do
    let(:format) { :xlsx }

    it "and saves it" do
      subject.perform

      expect(File.exist?("#{filepath}.#{format}"))
    end
  end
end
