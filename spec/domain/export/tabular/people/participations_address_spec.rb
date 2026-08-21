#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::ParticipationsAddress do
  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, participant: person, event: events(:top_course)) }
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

    before do
      person.phone_numbers.create!(category: contact_account_categories(:phone_number_person_landline),
        number: "0791234567")
    end

    it "includes category-based phone number columns" do
      expect(attribute_labels).to have_key(:phone_number_landline)
      expect(attribute_labels[:phone_number_landline]).to eq "Telefonnummer Festnetz"
      expect(row(0)[attributes.index(:phone_number_landline)]).to eq "+41 79 123 45 67"
    end
  end
end
