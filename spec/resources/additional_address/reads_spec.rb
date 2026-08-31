#  frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe AdditionalAddressResource, type: :resource do
  let(:user) { user_role.person }
  let(:ability) { Ability.new(user) }

  describe "serialization" do
    let(:role) { roles(:bottom_member) }
    let!(:person) { role.person }
    let!(:additional_address) {
      Fabricate(:additional_address, contactable: person, uses_contactable_name: false,
        first_name: "Jane", last_name: "Doe", organization: true, organization_name: "Acme Corp")
    }

    context "without appropriate permission" do
      let(:user) { Fabricate(:person) }

      it "does not expose data" do
        render
        expect(jsonapi_data).to eq([])
      end
    end

    context "with appropriate permission" do
      let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, person: Fabricate(:person), group: role.group) }

      it "works" do
        render
        data = jsonapi_data[0]
        expect(data.id).to eq(additional_address.id)
        expect(data.jsonapi_type).to eq("additional_addresses")
        expect(data.contactable_id).to eq person.id
        expect(data.contactable_type).to eq "Person"
        expect(data.first_name).to eq "Jane"
        expect(data.last_name).to eq "Doe"
        expect(data.organization).to eq true
        expect(data.organization_name).to eq "Acme Corp"
      end
    end
  end
end
