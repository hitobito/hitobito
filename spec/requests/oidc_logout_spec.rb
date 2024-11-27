# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe "GET /oidc/logout", type: :request do
  let(:scopes) { "openid with_roles" }
  let(:application) { Fabricate(:application, scopes: scopes) }
  let(:user) { people(:bottom_member) }
  let(:token) { Fabricate(:access_token, application: application, scopes: scopes, resource_owner_id: user.id) }

  context "without access token" do
    it "fails with HTTP 401 (unauthorized)" do
      get "/oidc/logout"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "without openid scope" do
    let(:scopes) { "with_roles" }

    it "fails with HTTP 403 (forbidden)" do
      get "/oidc/logout", headers: {Authorization: "Bearer " + token.token}
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "with openid scope" do
    let(:scopes) { "openid" }

    it "GET#destroy destroys token and redirects to new_person_session_url" do
      get "/oidc/logout", headers: {Authorization: "Bearer " + token.token}
      expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to redirect_to new_person_session_url(oauth: true)
    end

    it "POST#destroy destroys token and redirects to new_person_session_url" do
      post "/oidc/logout", headers: {Authorization: "Bearer " + token.token}
      expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to redirect_to new_person_session_url(oauth: true)
    end

    it "redirects to supplied url" do
      get "/oidc/logout", headers: {Authorization: "Bearer " + token.token}, params: {post_logout_redirect_uri: "http://example.com"}
      expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to redirect_to "http://example.com"
    end
  end
end
