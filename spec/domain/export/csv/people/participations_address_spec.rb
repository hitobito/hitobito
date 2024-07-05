#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"

describe Export::Tabular::People::ParticipationsAddress do
  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
  let(:list) { [participation] }
  let(:people_list) { Export::Tabular::People::ParticipationsAddress.new(list) }

  subject { people_list.attribute_labels }

  context "address data" do
    its([:first_name]) { should eq "Vorname" }
    its([:town]) { should eq "Ort" }
  end

  context "integration" do
    let(:simple_headers) do
      ["Vorname", "Nachname", "Übername", "Firmenname", "Firma", "Haupt-E-Mail",
        "Adresse", "PLZ", "Ort", "Land", "Hauptebene", "Rollen"]
    end

    let(:data) { Export::Tabular::People::ParticipationsAddress.export(:csv, list) }
    let(:data_without_bom) { data.gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), "") }
    let(:csv) { CSV.parse(data_without_bom, headers: true, col_sep: Settings.csv.separator) }

    subject { csv }

    its(:headers) { should == simple_headers }

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
