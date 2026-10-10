#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require "spec_helper"

describe PhoneNumberResource, type: :resource do
  let(:user) { user_role.person }
  let(:ability) { Ability.new(user) }

  describe "serialization" do
    let(:role) { roles(:bottom_member) }
    let!(:person) { role.person }
    let!(:phone_number) { Fabricate(:phone_number, contactable: person, public: false) }

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
        expect(data.id).to eq(phone_number.id)
        expect(data.jsonapi_type).to eq("phone_numbers")
        expect(data.contactable_id).to eq person.id
        expect(data.contactable_type).to eq "Person"
        expect(data.label).to eq phone_number.label
        expect(data.number).to eq phone_number.number
        expect(data.public).to eq phone_number.public
        expect(data.category_id).to eq phone_number.category_id
      end

      it "sideloads the category" do
        params[:include] = "category"
        render
        category_data = d[0].sideload(:category)
        expect(category_data.id).to eq phone_number.category_id
        expect(category_data.jsonapi_type).to eq "contact_account_categories"
        expect(category_data.key).to eq phone_number.category.key
      end
    end
  end
end
