#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"

describe Export::Tabular::People::ParticipationsAddress do
  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, participant: person, event: events(:top_course)) }
  let(:scope) do
    participations = Event::Participation.where(id: participation.id)
    Event::Participation::PreloadParticipations.preload(participations)
    participations
  end
  let(:people_list) { Export::Tabular::People::ParticipationsAddress.new(scope) }

  subject { people_list.attribute_labels }

  context "address data" do
    its([:first_name]) { should eq "Vorname" }
    its([:town]) { should eq "Ort" }
  end

  context "integration" do
    let(:simple_headers) do
      ["Vorname", "Nachname", "Übername", "Firmenname", "Firma", "Haupt-E-Mail",
        "zusätzliche Adresszeile", "Strasse", "Hausnummer", "Postfach", "PLZ", "Ort", "Land",
        "Hauptebene", "Rollen"]
    end

    let(:data) { Export::Tabular::People::ParticipationsAddress.export(:csv, scope) }
    let(:data_without_bom) { data.gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), "") }
    let(:csv) { CSV.parse(data_without_bom, headers: true, col_sep: Settings.csv.separator) }

    subject { csv }

    it "has headers" do
      headers = subject.headers

      expect(headers).to match_array(simple_headers)
      expect(headers.join("\n")).to eql(simple_headers.join("\n"))
    end

    context "first row" do
      subject { csv[0] }

      its(["Vorname"]) { should eq person.first_name }
      its(["Rollen"]) { should be_blank }

      context "with roles" do
        before do
          Fabricate(:event_role, participation: participation, type: "Event::Role::Leader")
          Fabricate(:event_role, participation: participation, type: "Event::Role::AssistantLeader")
          participation.reload
        end

        its(["Rollen"]) { should eq "Hauptleitung, Leitung" }
      end
    end
  end
end
