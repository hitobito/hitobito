require "rails_helper"

describe "OauthWorkflow" do
  let(:user) { people(:top_leader) }
  let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
  let(:password) { "cNb@X7fTdiU4sWCMNos3gJmQV_d9e9" }

  before do
    @app = Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri)
  end

  def jwt_decode(payload)
    JWT.decode(payload, key.public_key, true, algorithms: "RS256").first
  end

  describe "obtaining grant" do
    it "redirects to oauth login if not authenticated" do
      get oauth_authorization_path,
        params: {client_id: @app.uid, client_secret: @app.secret, redirect_uri: redirect_uri, response_type: :code,
                 scope: :openid, prompt: :login}
      expect(response).to redirect_to("http://www.example.com/de/users/sign_in?oauth=true")
    end

    it "redirects to oauth login if authenticated but login is set to prompt" do
      sign_in(user)
      get oauth_authorization_path,
        params: {client_id: @app.uid, client_secret: @app.secret, redirect_uri: redirect_uri, response_type: :code,
                 scope: :openid, prompt: "login"}
      expect(response).to redirect_to("http://www.example.com/de/users/sign_in?oauth=true")
    end

    it "prompts for authorization if authenticated and no prompt is set" do
      sign_in(user)
      get oauth_authorization_path,
        params: {client_id: @app.uid, client_secret: @app.secret, redirect_uri: redirect_uri, response_type: :code,
                 scope: :openid}
      expect(response).to be_successful
      expect(response.body).to include "Autorisierung erforderlich"
    end

    it "strips prompt param from after_sign_in path" do
      user.update!(password: password)
      get oauth_authorization_path,
        params: {client_id: @app.uid, client_secret: @app.secret, redirect_uri: redirect_uri, response_type: :code,
                 scope: :openid, prompt: :login}
      post person_session_path, params: {person: {login_identity: user.email, password: password}}

      query = CGI.parse(URI.parse(response.headers["Location"]).query)
      expect(query).not_to have_key("prompt")
      expect(query).to have_key("client_id")
    end
  end

  describe "obtaining token" do
    it "creates access_token for the user", :time_frozen do
      grant = @app.access_grants.create!(resource_owner_id: user.id, expires_in: 10, redirect_uri: redirect_uri)
      expect do
        post oauth_token_path,
          params: {client_id: @app.uid, client_secret: @app.secret, redirect_uri: redirect_uri, code: grant.token,
                   grant_type: "authorization_code"}
      end.to change { Oauth::AccessToken.count }.by(1)
      expect(json["created_at"]).to be_present
      expect(json["access_token"]).to be_present
      expect(json["refresh_token"]).to be_present
      expect(json["token_type"]).to eq "Bearer"
      expect(json["expires_in"]).to eq 2.hours.to_i
    end

    it "can configure token expiry", :time_frozen do
      grant = @app.access_grants.create!(resource_owner_id: user.id, expires_in: 10, redirect_uri: redirect_uri)
      allow(Doorkeeper.config).to receive(:access_token_expires_in).and_return(1.hour)
      post oauth_token_path,
        params: {client_id: @app.uid, client_secret: @app.secret, redirect_uri: redirect_uri, code: grant.token,
                 grant_type: "authorization_code"}
      expect(json["expires_in"]).to eq 1.hours.to_i
    end

    context "with jwt" do
      let(:key) { OpenSSL::PKey::RSA.generate(2048) }

      before do
        allow(Settings.oidc).to receive(:signing_key).and_return(key.to_s.lines)
        allow(Doorkeeper::OpenidConnect.configuration).to receive(:signing_key).and_return(key.to_s)
        expect(Doorkeeper::JWT.configuration).to receive(:secret_key).and_return(key.to_s)
        expect(Doorkeeper.config).to receive(:access_token_generator).and_return("::Doorkeeper::JWT")
      end

      def make_request_with(grant)
        post oauth_token_path, params: {
          client_id: @app.uid, client_secret: @app.secret, redirect_uri: redirect_uri, code: grant.token,
          grant_type: "authorization_code"
        }
      end

      def create_grant(scopes: nil)
        @app.access_grants.create!(resource_owner_id: user.id, expires_in: 10, redirect_uri:, scopes:)
      end

      it "returns jwt as access_token" do
        make_request_with(create_grant)
        expect(json.keys).to match_array(
          %w[access_token token_type expires_in created_at refresh_token]
        )
        expect(jwt_decode(json["access_token"])["exp"]).to be_within(10).of(2.hours.from_now.to_i)
      end

      it "can configure scopes" do
        @app.update(scopes: "email openid")
        make_request_with(create_grant(scopes: "email openid"))
        expect(json.keys).to match_array(
          %w[access_token token_type expires_in created_at scope id_token refresh_token]
        )
        expect(jwt_decode(json["id_token"])["exp"]).to be_within(10).of(2.minutes.from_now.to_i)
      end

      it "can configure expiry of id token" do
        @app.update(scopes: "email openid")
        allow(Doorkeeper::OpenidConnect.configuration).to receive(:expiration).and_return(2.hours)
        make_request_with(create_grant(scopes: "email openid"))
        expect(jwt_decode(json["id_token"])["exp"]).to be_within(10).of(2.hours.from_now.to_i)
      end
    end
  end

  describe "refreshing token" do
    it "refreshes an access_token for the user", :time_frozen do
      grant = @app.access_grants.create!(resource_owner_id: user.id, expires_in: 10, redirect_uri: redirect_uri)
      post oauth_token_path,
        params: {client_id: @app.uid, client_secret: @app.secret, redirect_uri: redirect_uri,
                 code: grant.token, grant_type: "authorization_code"}
      refresh_token = json["refresh_token"]

      expect do
        post oauth_token_path,
          params: {client_id: @app.uid, client_secret: @app.secret, refresh_token: refresh_token,
                   grant_type: "refresh_token"}
      end.to change { Oauth::AccessToken.count }.by(1)
      expect(json["created_at"]).to be_present
      expect(json["access_token"]).to be_present
      expect(json["refresh_token"]).to be_present
      expect(json["token_type"]).to eq "Bearer"
      expect(json["expires_in"]).to eq 2.hours.to_i
    end

    def obtain_tokens
      grant = @app.access_grants.create!(resource_owner_id: user.id, expires_in: 10, redirect_uri:,
        scopes: "email")
      post oauth_token_path,
        params: {client_id: @app.uid, client_secret: @app.secret, redirect_uri:,
                 code: grant.token, grant_type: "authorization_code"}
      json
    end

    def refresh_with(refresh_token)
      post oauth_token_path,
        params: {client_id: @app.uid, client_secret: @app.secret, refresh_token:,
                 grant_type: "refresh_token"}
    end

    def use_access_token(access_token)
      get oauth_profile_path, headers: {"Authorization" => "Bearer #{access_token}"}
      expect(response).to have_http_status(:ok)
    end

    shared_examples "refresh token revocation" do
      it "accepts the old refresh token again as long as the new access token is unused" do
        old_refresh_token = obtain_tokens["refresh_token"]
        refresh_with(old_refresh_token)
        expect(response).to have_http_status(:ok)

        refresh_with(old_refresh_token)
        expect(response).to have_http_status(:ok)
        expect(json["access_token"]).to be_present
      end

      it "rejects the old refresh token once the new access token has been used" do
        old_refresh_token = obtain_tokens["refresh_token"]
        refresh_with(old_refresh_token)
        new_tokens = json

        use_access_token(new_tokens["access_token"])

        refresh_with(old_refresh_token)
        expect(response).to have_http_status(:bad_request)
        expect(json["error"]).to eq "invalid_grant"

        refresh_with(new_tokens["refresh_token"])
        expect(response).to have_http_status(:ok)
      end
    end

    it_behaves_like "refresh token revocation"

    context "with jwt" do
      let(:key) { OpenSSL::PKey::RSA.generate(2048) }

      before do
        allow(Settings.oidc).to receive(:signing_key).and_return(key.to_s.lines)
        allow(Doorkeeper::JWT.configuration).to receive(:secret_key).and_return(key.to_s)
        allow(Doorkeeper.config).to receive(:access_token_generator).and_return("::Doorkeeper::JWT")
      end

      it "issues jwt access tokens" do
        refresh_with(obtain_tokens["refresh_token"])
        expect(jwt_decode(json["access_token"])["sub"]).to eq user.id
      end

      it_behaves_like "refresh token revocation"
    end
  end

  context "using token" do
    it "might use access token without scope" do
      token = @app.access_tokens.create!(resource_owner_id: user.id, scopes: "api")
      get group_person_path(group_id: user.primary_group_id, id: user.id),
        headers: {"Authorization" => "Bearer #{token}"}
      expect(response.status).to eq 200
    end

    it "returns different representation for different scope" do
      token = @app.access_tokens.create!(resource_owner_id: user.id, scopes: "email name")
      get oauth_profile_path, headers: {"Authorization" => "Bearer #{token}", :"X-Scope" => "name"}
      expect(json.keys).to eq ["id", "email", "first_name", "last_name", "nickname", "address", "address_care_of",
        "street", "housenumber", "postbox", "zip_code", "town", "country", "given_name", "family_name"]
    end

    it "return error if scope is not configured on application" do
      token = @app.access_tokens.create!(resource_owner_id: user.id, scopes: "email")
      get oauth_profile_path, headers: {"Authorization" => "Bearer #{token}", :"X-Scope" => "name"}
      expect(response.status).to eq 403
      expect(json.keys).to eq %w[error]
    end
  end

  def json
    JSON.parse(response.body)
  end
end
