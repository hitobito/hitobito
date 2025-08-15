# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Synchronize::Addresses::SwissPost::ResultProcessor do
  let(:result) { Rails.root.join("spec", "support", "synchronize", "addresses", "swiss_post", "result.txt").read }
  let(:top_leader) { people(:top_leader) }
  let(:options) { {col_sep: "\t", row_sep: "\r\n", headers: true} }
  let(:log_entry) { HitobitoLogEntry.last }
  let(:log_entry_attrs) { {category: "cleanup", subject: top_leader, level: "info"} }

  def process_with
    data = CSV.parse(result, **options)
    yield data
    described_class.new(data.to_csv(**options)).process
  end

  subject(:processor) { described_class.new(result) }

  describe "single field update" do
    it "updates housenumber" do
      expect do
        processor.process
      end.to change { top_leader.reload.housenumber.to_i }.from(345).to(123)
    end

    it "creates version and no log entry", versioning: true do
      expect do
        processor.process
      end.to change { top_leader.versions.count }.by(1)
        .and not_change { HitobitoLogEntry.count }
    end

    it "updates multiple fields" do
      expect do
        process_with do |data|
          data.entries.last["HouseNo"] = "321"
          data.entries.last["ZIPCode"] = "1234"
        end
      end.to change { top_leader.reload.housenumber.to_i }.from(345).to(321)
        .and change { top_leader.zip_code }.to("1234")
    end

    {
      first_name: "Prename",
      last_name: "Name",
      address_care_of: "CoAddress",
      street: "StreetName",
      town: "TownName"
    }.each do |attr, field|
      it "updates #{attr} from #{field}" do
        expect do
          process_with do |data|
            data.entries.last[field] = field
          end
        end.to change { top_leader.reload.send(attr) }.to(field)
      end
    end

    describe "updating postbox" do
      it "ignores anything if POBoxTerm is blank" do
        process_with do |data|
          data.entries.last["POTerm"] = ""
          data.entries.last["POBoxNo"] = 10
          data.entries.last["POBoxZIP"] = 1235
          data.entries.last["POBoxTownName"] = "Greatesttown"
        end
        expect(top_leader.reload.postbox).to be_nil
      end

      it "resets postbox if POBoxTerm is blank" do
        top_leader.update!(postbox: "Postfach 1234")
        process_with do |data|
          data.entries.last["POTerm"] = ""
        end
        expect(top_leader.reload.postbox).to be_nil
      end

      it "updates postbox from postbox fields" do
        process_with do |data|
          data.entries.last["POBoxTerm"] = "Postfach"
          data.entries.last["POBoxNo"] = 10
          data.entries.last["POBoxZIP"] = 1235
          data.entries.last["POBoxTownName"] = "Greatesttown"
        end
        expect(top_leader.reload.postbox).to eq "Postfach 10 1235 Greatesttown"
      end

      it "falls back to person zip if POBoxZIP is blank" do
        process_with do |data|
          data.entries.last["POBoxTerm"] = "Postfach"
          data.entries.last["POBoxNo"] = 10
          data.entries.last["POBoxTownName"] = "Greatesttown"
        end
        expect(top_leader.reload.postbox).to eq "Postfach 10 3456 Greatesttown"
      end

      it "falls back to person town if POBoxTownName is blank" do
        process_with do |data|
          data.entries.last["POBoxTerm"] = "Postfach"
          data.entries.last["POBoxNo"] = 10
        end
        expect(top_leader.reload.postbox).to eq "Postfach 10 3456 Greattown"
      end

      it "handles blank POBoxNo" do
        process_with do |data|
          data.entries.last["POBoxTerm"] = "Postfach"
        end
        expect(top_leader.reload.postbox).to eq "Postfach 3456 Greattown"
      end
    end

    it "logs error but does not raise if person is invalid after update" do
      expect do
        process_with do |data|
          data.entries.last["ZIPCode"] = "invalid"
        end
      end.to change { HitobitoLogEntry.count }.by(1)
        .and not_change { top_leader.reload.attributes }
      expect(log_entry).to have_attributes(log_entry_attrs.merge(
        # rubocop:todo Layout/LineLength
        message: "Die Personendaten der Post konnten für Top Leader (572407901) nicht übernommen werden", level: "error"
        # rubocop:enable Layout/LineLength
      ))
    end
  end

  describe "ignored updates" do
    [
      ["26", "info", "Umzug ins Ausland"],
      ["27", "info", "Unbekannt weggezogen"],
      ["50", "warn", "Person an Adresse nicht bekannt"],
      ["51", "warn", "Adresse nicht bekannt"]
    ].each do |qstat, level, message|
      it "creates log entry for qstat #{qstat}" do
        expect do
          process_with do |data|
            data.entries.last["QSTAT"] = qstat
          end
        end.to change { HitobitoLogEntry.count }
          .and not_change { top_leader.reload.attributes }
        expect(log_entry).to have_attributes(log_entry_attrs.merge(message:, level:))
      end
    end
  end
end
