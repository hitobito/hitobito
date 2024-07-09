# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

describe "roles#update", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let(:role) { roles(:top_leader) }
    let(:payload) { {} }

    subject(:make_request) do
      jsonapi_put "/api/roles/#{role.id}", payload
    end

    describe "basic update" do
      let(:payload) do
        {
          data: {
            id: role.id.to_s,
            type: "roles",
            attributes: {
              label: "Bobby"
            }
          }
        }
      end

      it "updates the resource" do
        expect(RoleResource).to receive(:find).and_call_original
        expect {
          make_request
          expect(response.status).to eq(200), response.body
        }.to change { role.reload.label }.to("Bobby")
      end
    end
  end
end
