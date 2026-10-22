# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "rails_helper"

RSpec.describe "contact_account_categories#show", type: :request do
  it_behaves_like "jsonapi authorized requests", required_scopes: [:people] do
    let(:category) { contact_account_categories(:phone_number_person_mobile) }

    subject(:make_request) do
      jsonapi_get "/api/contact_account_categories/#{category.id}", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(ContactAccountCategoryResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200)
        expect(d.jsonapi_type).to eq("contact_account_categories")
        expect(d.id).to eq(category.id)
        expect(d.key).to eq("mobile")
      end
    end
  end
end
