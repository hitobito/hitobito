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
    its([:first_name]) { is_expected.to eq "Vorname" }
    its([:town]) { is_expected.to eq "Ort" }
  end

  context "integration" do
    let(:simple_headers) do
      ["Vorname", "Nachname", "Übername", "Firmenname", "Firma", "Haupt-E-Mail",
       "Adresse", "PLZ", "Ort", "Land", "Geschlecht", "Geburtstag", "Hauptebene", "Rollen", "Tags",]
    end

    let(:data) { Export::Tabular::People::ParticipationsAddress.export(:csv, list) }
    let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }

    subject { csv }

    its(:headers) { is_expected.to == simple_headers }

    context "first row" do
      subject { csv[0] }

      its(["Vorname"]) { is_expected.to eq person.first_name }
      its(["Rollen"]) { is_expected.to be_blank }

      context "with roles" do
        before do
          Fabricate(:event_role, participation: participation, type: "Event::Role::Leader")
          Fabricate(:event_role, participation: participation, type: "Event::Role::AssistantLeader")
          participation.reload
        end

        its(["Rollen"]) { is_expected.to eq "Hauptleitung, Leitung" }
      end
    end
  end
end
