# frozen_string_literal: true

#  Copyright (c) 2023-2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

RSpec.describe "people#show", type: :request do
  it_behaves_like "jsonapi authorized requests", required_scopes: [:people] do
    let(:params) { {} }
    let!(:requested_person) { people(:top_leader) }

    subject(:make_request) do
      jsonapi_get "/api/people/#{requested_person.id}", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(PersonResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200)
        expect(d.jsonapi_type).to eq("people")
        expect(d.id).to eq(requested_person.id)
      end
    end

    describe "contact account category_name" do
      let(:params) do
        {include: "phone_numbers", extra_fields: {phone_numbers: "category_name"}}
      end
      let!(:phone_number) do
        Fabricate(:phone_number, contactable: requested_person,
          category: contact_account_categories(:phone_number_person_mobile))
      end

      it "returns the translated category name" do
        make_request
        expect(response.status).to eq(200), response.body
        node = included("phone_numbers").find { |n| n.id == phone_number.id }
        expect(node[:category_name]).to eq(phone_number.category.name)
      end
    end
  end
end
