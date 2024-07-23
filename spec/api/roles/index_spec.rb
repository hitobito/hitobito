# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "roles#index", type: :request do
  it_behaves_like "jsonapi authorized requests", required_flags: [:people, :groups] do
    let(:params) { {} }
    subject(:make_request) do
      jsonapi_get "/api/roles", params:
    end

    describe "basic fetch" do
      it "works" do
        expect(RoleResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["roles"])
        expect(d.map(&:id)).to match_array(people(:top_leader, :bottom_member).pluck(:id))
      end
    end

    describe "unsupported param include" do
      let(:params) { {include: "foobar"} }

      it "reports 400 instead of server error" do
        make_request
        expect(response.status).to eq(400), response.body
        expect(response.body).to include("Unsupported include parameter")
      end
    end
  end
end
