# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "rails_helper"

RSpec.describe "contact_account_categories#index", type: :request do
  it_behaves_like "jsonapi authorized requests", required_scopes: [:people] do
    let(:params) { {page: {size: 100}} }

    subject(:make_request) { jsonapi_get "/api/contact_account_categories", params: params }

    describe "basic fetch" do
      it "works" do
        expect(ContactAccountCategoryResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["contact_account_categories"])
        expect(d.map(&:id)).to match_array(ContactAccountCategory.pluck(:id))
      end
    end
  end
end
