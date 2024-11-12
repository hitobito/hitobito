# frozen_string_literal: true

#  Copyright (c) 2020-2024, Aargauer OL-Verband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe "GET oauth/userinfo", type: :request do
  let(:scopes) { "openid with_roles" }
  let(:application) { Fabricate(:application, scopes: scopes) }
  let(:user) { people(:bottom_member) }
  let(:token) { Fabricate(:access_token, application: application, scopes: scopes, resource_owner_id: user.id) }
  let(:userinfo) { JSON.parse(response.body).deep_symbolize_keys }

  context "without access token" do
    it "fails with HTTP 401 (unauthorized)" do
      get "/oauth/userinfo"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "without openid scope" do
    let(:scopes) { "with_roles" }

    it "fails with HTTP 401 (unauthorized)" do
      get "/oauth/userinfo"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with openid scope" do
    let(:scopes) { "openid" }

    it "succeeds and returns subject" do
      get "/oauth/userinfo", headers: {Authorization: "Bearer " + token.token}, params: {token: token.token}

      expect(response).to have_http_status(:ok)
      expect(userinfo).to eq({sub: user.id.to_s})
    end
  end

  context "with openid and email scope" do
    let(:scopes) { "openid email" }

    it "succeeds and returns subject" do
      get "/oauth/userinfo", headers: {Authorization: "Bearer " + token.token}, params: {token: token.token}

      expect(response).to have_http_status(:ok)
      expect(userinfo).to eq({sub: user.id.to_s, email: "bottom_member@example.com"})
    end
  end

  context "with openid and with_roles scope" do
    let(:scopes) { "openid with_roles" }

    it "succeeds and returns user attributes and roles" do
      get "/oauth/userinfo", headers: {Authorization: "Bearer " + token.token}, params: {token: token.token}

      expect(response).to have_http_status(:ok)
      expect(userinfo).to eq({sub: "382461928",
        first_name: "Bottom",
        last_name: "Member",
        nickname: nil,
        company_name: nil,
        company: false,
        email: "bottom_member@example.com",
        address_care_of: nil,
        street: "Greatstreet",
        housenumber: "345",
        postbox: nil,
        zip_code: "3456",
        town: "Greattown",
        country: "CH",
        gender: nil,
        birthday: nil,
        primary_group_id: 376803389,
        language: "de",
        address: "Greatstreet 345",
        roles: [{group_id: 376803389,
                 group_name: "Bottom One",
                 role: "Group::BottomLayer::Member",
                 role_class: "Group::BottomLayer::Member",
                 role_name: "Member",
                 permissions: ["layer_and_below_read", "finance"]}]})
    end
  end
end
