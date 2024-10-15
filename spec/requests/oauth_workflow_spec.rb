require "rails_helper"

describe "OauthWorkflow" do
  let(:user) { people(:top_leader) }
  let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }

  describe "obtaining token" do
    it "creates access_token for the user" do
      app = Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri)
      grant = app.access_grants.create!(resource_owner_id: user.id, expires_in: 10, redirect_uri: redirect_uri)
      expect do
        post oauth_token_path, params: {client_id: app.uid, client_secret: app.secret, redirect_uri: redirect_uri, code: grant.token, grant_type: "authorization_code"}
      end.to change { Oauth::AccessToken.count }.by(1)
      expect(json["created_at"]).to be_present
      expect(json["access_token"]).to be_present
      expect(json["token_type"]).to eq "Bearer"
      expect(json["expires_in"]).to eq 2.hours.to_i
    end

    it "can configure token expiry" do
      app = Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri)
      grant = app.access_grants.create!(resource_owner_id: user.id, expires_in: 10, redirect_uri: redirect_uri)
      allow(Doorkeeper.config).to receive(:access_token_expires_in).and_return(1.hour)
      post oauth_token_path, params: {client_id: app.uid, client_secret: app.secret, redirect_uri: redirect_uri, code: grant.token, grant_type: "authorization_code"}
      expect(json["expires_in"]).to eq 1.hours.to_i
    end

    context "with jwt" do
      let(:key) { OpenSSL::PKey::RSA.generate(1024) }

      before do
        allow(Settings.oidc).to receive(:signing_key).and_return(key.to_s.lines)
        expect(Doorkeeper::JWT.configuration).to receive(:secret_key).and_return(key.to_s)
        expect(Doorkeeper.config).to receive(:access_token_generator).and_return("::Doorkeeper::JWT")
      end

      it "returns jwt as access_token" do
        app = Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri)
        grant = app.access_grants.create!(resource_owner_id: user.id, expires_in: 10, redirect_uri: redirect_uri)
        post oauth_token_path, params: {client_id: app.uid, client_secret: app.secret, redirect_uri: redirect_uri, code: grant.token, grant_type: "authorization_code"}
        jwt = JWT.decode(json["access_token"], key.public_key, true, algorithms: "RS256")
        expect(jwt.first.keys.sort).to match_array %w[iss aud iat exp jti sub]
      end
    end
  end

  context "using token" do
    before do
      @app = Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri)
      Doorkeeper.configure do
        force_ssl_in_redirect_uri { false }
      end
    end

    it "might use access token without scope" do
      token = @app.access_tokens.create!(resource_owner_id: user.id, scopes: "api")
      get group_person_path(group_id: user.primary_group_id, id: user.id), headers: {"Authorization" => "Bearer #{token}"}
      expect(response.status).to eq 200
    end

    it "returns different representation for different scope" do
      token = @app.access_tokens.create!(resource_owner_id: user.id, scopes: "email name")
      get oauth_profile_path, headers: {"Authorization" => "Bearer #{token}", :"X-Scope" => "name"}
      expect(json.keys).to eq ["id", "email", "first_name", "last_name", "nickname", "address", "address_care_of",
        "street", "housenumber", "postbox", "zip_code", "town", "country"]
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
