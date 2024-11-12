# frozen_string_literal: true

#  Copyright (c) 2020-2024, Aargauer OL-Verband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe "GET oauth/revoke", type: :request do
  let(:application) { Fabricate(:application) }

  let(:user) { people(:bottom_member) }

  context "without access token" do
    it "fails with HTTP 403 (forbidden)" do
      post "/oauth/revoke"
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "with access token" do
    let(:token) { Fabricate(:access_token, application: application, scopes: "email", resource_owner_id: user.id) }

    context "confidential client" do
      before { application.update!(confidential: true) }

      it "fails with HTTP 403 (forbidden) for public if incomplete" do
        post "/oauth/revoke", headers: {Authorization: "Bearer " + token.token}, params: {token: token.token, client_id: application.uid}

        expect(response).to have_http_status(:forbidden)

        get "/oauth/profile", headers: {Authorization: "Bearer " + token.token}
        expect(response).to have_http_status(:ok)
      end

      it "succeeds with HTTP 200 when sending client_id" do
        post "/oauth/revoke", headers: {Authorization: "Bearer " + token.token}, params: {token: token.token, client_id: application.uid, client_secret: application.secret}

        expect(response).to have_http_status(:ok)

        get "/oauth/profile", headers: {Authorization: "Bearer " + token.token}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "public client" do
      before { application.update!(confidential: false) }

      it "fails with HTTP 403 (forbidden) for public if incomplete" do
        post "/oauth/revoke", headers: {Authorization: "Bearer " + token.token}, params: {token: token.token}

        expect(response).to have_http_status(:forbidden)

        get "/oauth/profile", headers: {Authorization: "Bearer " + token.token}
        expect(response).to have_http_status(:ok)
      end

      it "succeeds with HTTP 200 when sending client_id and client_secret" do
        post "/oauth/revoke", headers: {Authorization: "Bearer " + token.token}, params: {token: token.token, client_id: application.uid}

        expect(response).to have_http_status(:ok)

        get "/oauth/profile", headers: {Authorization: "Bearer " + token.token}
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
