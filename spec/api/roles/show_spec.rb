# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

describe "roles#show", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let(:params) { {} }
    let!(:role) { roles(:top_leader) }

    subject(:make_request) do
      jsonapi_get "/api/roles/#{role.id}", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(RoleResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200)
        expect(d.jsonapi_type).to eq("roles")
        expect(d.id).to eq(role.id)
      end
    end
  end
end
