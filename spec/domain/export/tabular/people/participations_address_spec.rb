#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::ParticipationsAddress do
  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
  let(:scope) { Event::Participation.where(id: participation.id) }
  let(:people_list) { Export::Tabular::People::ParticipationsAddress.new(scope) }

  subject { people_list.attribute_labels }

  context "address data" do
    its([:first_name]) { should eq "Vorname" }
    its([:town]) { should eq "Ort" }
  end

  describe "Phone Numbers" do
    def row(index) = people_list.data_rows.to_a[index]

    let(:attributes) { people_list.attributes }
    let(:attribute_labels) { people_list.attribute_labels }

    before { PhoneNumber.create!(contactable: person, label: "Privat", number: "0791234567") }

    it "includes phone number" do
      expect(attribute_labels.keys).to have(13).items
      expect(attribute_labels).to have_key(:phone_number_privat)
      expect(attribute_labels[:phone_number_privat]).to eq "Telefonnummer Privat"
      expect(row(0)[attributes.index(:phone_number_privat)]).to eq "+41 79 123 45 67"
    end
  end
end
