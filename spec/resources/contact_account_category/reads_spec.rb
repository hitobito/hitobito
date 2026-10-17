# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ContactAccountCategoryResource, type: :resource do
  let(:category) { contact_account_categories(:phone_number_person_mobile) }

  describe "serialization" do
    before { params[:filter] = {id: {eq: category.id}} }

    it "works" do
      render
      data = jsonapi_data[0]
      expect(data.attributes.symbolize_keys.keys).to match_array [:id, :jsonapi_type,
        :key, :name, :contact_account_type, :contactable_type, :unique_per_contactable,
        :position]

      expect(data.id).to eq(category.id)
      expect(data.jsonapi_type).to eq("contact_account_categories")
      expect(data.key).to eq("mobile")
      expect(data.contact_account_type).to eq("PhoneNumber")
      expect(data.contactable_type).to eq("Person")
      expect(data.unique_per_contactable).to eq(true)
      expect(data.position).to eq(0)
    end

    it "translates the name to the current locale" do
      I18n.with_locale(:fr) { render }
      expect(jsonapi_data[0].name).to eq("Mobile")
    end
  end

  describe "filtering" do
    it "filters by contact_account_type and contactable_type" do
      params[:filter] = {contact_account_type: {eq: "PhoneNumber"},
                         contactable_type: {eq: "Person"}}
      render
      expected = ContactAccountCategory.where(contact_account_type: "PhoneNumber",
        contactable_type: "Person")
      expect(jsonapi_data.map(&:id)).to match_array(expected.pluck(:id))
    end

    it "filters by key" do
      params[:filter] = {contact_account_type: {eq: "PhoneNumber"},
                         contactable_type: {eq: "Person"}, key: {eq: "other"}}
      render
      expect(jsonapi_data.map(&:id))
        .to eq([contact_account_categories(:phone_number_person_other).id])
    end
  end

  describe "scopes" do
    context "without people scope" do
      let(:current_scopes) { %w[groups] }

      it "does not expose data" do
        render
        expect(jsonapi_data).to eq([])
      end
    end

    context "with people scope" do
      let(:current_scopes) { %w[people] }

      it "exposes data" do
        params[:page] = {size: 100}
        render
        expect(jsonapi_data.map(&:id)).to match_array(ContactAccountCategory.pluck(:id))
      end
    end
  end
end
