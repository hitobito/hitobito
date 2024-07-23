# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

describe "roles#delete", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let!(:role) { roles(:bottom_member).tap { |r| r.update!(created_at: 1.year.ago) } }
    let(:payload) { {} }

    subject(:make_request) do
      jsonapi_delete "/api/roles/#{role.id}"
    end

    describe "basic delete" do
      let(:payload) do
        {
          data: {
            id: role.id.to_s,
            type: "roles"
          }
        }
      end

      it "soft destroys role", versioning: true do
        expect(RoleResource).to receive(:find).and_call_original
        expect {
          make_request
          expect(response.status).to eq(200), response.body
        }.to change { Role.count }.by(-1)
          .and change { role.versions.count }.by(1)
          .and not_change { Role.with_deleted.count }
      end
    end
  end
end
