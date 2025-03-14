# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe "GET /oidc/logout", type: :request do
  let(:scopes) { "openid with_roles" }
  let(:application) { Fabricate(:application, scopes: scopes) }
  let(:person) { people(:bottom_member) }
  let(:token) { Fabricate(:access_token, application: application, scopes: scopes, resource_owner_id: person.id) }

  context "without id token" do
    it "fails with HTTP 422 (unprocessable_entity)" do
      get "/oidc/logout"
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to eq "failed to process token"
    end
  end

  context "with id token" do
    let(:id_token) { Doorkeeper::OpenidConnect::IdToken.new(token) }

    let(:key) { OpenSSL::PKey::RSA.generate(1024) }

    before do
      allow(Doorkeeper::OpenidConnect.configuration).to receive(:signing_key).and_return(key.to_s)
      allow(Doorkeeper::OpenidConnect.configuration).to receive(:signing_algorithm).and_return(:rs256)
      allow(Doorkeeper::OpenidConnect.configuration).to receive(:resource_owner_from_access_token).and_return(->(_token) { person })
    end

    it "GET#destroy destroys token and redirects to new_person_session_url" do
      get "/oidc/logout", params: {id_token_hint: id_token.as_jws_token}
      expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to redirect_to new_person_session_url(oauth: true)
    end

    it "POST#destroy destroys token and redirects to new_person_session_url" do
      post "/oidc/logout", params: {id_token_hint: id_token.as_jws_token}
      expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to redirect_to new_person_session_url(oauth: true)
    end

    it "destroys all associated access tokens" do
      other = Fabricate(:access_token, application: application, scopes: scopes, resource_owner_id: person.id)
      get "/oidc/logout", params: {id_token_hint: id_token.as_jws_token}
      expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { other.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "destroys all associated access tokens" do
      other = Fabricate(:access_token, application: application, scopes: scopes, resource_owner_id: person.id)
      get "/oidc/logout", params: {id_token_hint: id_token.as_jws_token}
      expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { other.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "destroys associated login session" do
      password = "cNb@X7fTdiU4sWCMNos3gJmQV_d9e9"
      person.update!(password: password)
      expect do
        post "/users/sign_in", params: {person: {login_identity: person.email, password: password}}
      end.to change { Session.where(person_id: person.id).count }.by(1)
      expect do
        get "/oidc/logout", params: {id_token_hint: id_token.as_jws_token}
      end.to change { Session.where(person_id: person.id).count }.by(-1)
    end

    it "destroys all sessions associated with that person" do
      2.times { Session.create!(person_id: person.id, session_id: SecureRandom.hex, data: {}) }
      expect do
        get "/oidc/logout", params: {id_token_hint: id_token.as_jws_token}
      end.to change { Session.where(person_id: person.id).count }.by(-2)
    end

    it "does not destroy tokens associated with another application" do
      other_application = Fabricate(:application, scopes: scopes)
      other = Fabricate(:access_token, application: other_application, scopes: scopes, resource_owner_id: person.id)
      get "/oidc/logout", params: {id_token_hint: id_token.as_jws_token}
      expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { other.reload }.not_to raise_error
    end

    it "redirects to supplied url" do
      get "/oidc/logout", params: {id_token_hint: id_token.as_jws_token, post_logout_redirect_uri: "http://example.com"}
      expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to redirect_to "http://example.com"
    end

    describe "state param" do
      it "includes state param in redirection request" do
        get "/oidc/logout", params: {id_token_hint: id_token.as_jws_token, post_logout_redirect_uri: "http://example.com", state: :foo}
        expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to redirect_to "http://example.com?state=foo"
      end

      it "adds state param in redirection request" do
        get "/oidc/logout", params: {id_token_hint: id_token.as_jws_token, post_logout_redirect_uri: "http://example.com?foo=bar", state: :foo}
        expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to redirect_to "http://example.com?foo=bar&state=foo"
      end
    end
  end
end
