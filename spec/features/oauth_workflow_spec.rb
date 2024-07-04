require "spec_helper"

describe "OauthWorkflow" do
  let(:user) { people(:top_leader) }
  let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }

  before { sign_in }

  it "creates new application" do
    visit root_path
    within("#page-navigation") do
      click_link "Einstellungen"
      click_link "OAuth Applikationen"
    end
    click_link "Erstellen"
    fill_in "Name", with: "MyApp"
    fill_in "Redirect URI", with: "urn:ietf:wg:oauth:2.0:oob"
    check "name", id: "oauth_application_scope_name"
    check "email"
    within(".bottom") do
      click_button "Speichern"
    end
  end

  it "creates access_grant for the user" do
    app = Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri)
    visit oauth_application_path(app)
    click_link "Autorisierungen"

    click_link "Autorisieren"

    expect(page).to have_text "Autorisierung erforderlich"
    expect(page).to have_content "Soll MyApp zur Nutzung dieses Kontos autorisiert werden?"
    expect(page).to have_content "Diese Anwendung erhält folgende Berechtigungen:"
    expect(page).to have_content "Lesen deiner E-Mail Adresse"

    expect do
      click_button "Autorisieren"
      expect(page).to have_content "Autorisierungscode"
    end.to change { app.access_grants.count }.by(1)

    code = find("#authorization_code").text
    visit oauth_application_path(app)
    click_link "Autorisierungen"
    expect(page).not_to have_content code
  end

  it "creates access_grant and skips consent" do
    app = Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri, skip_consent_screen: true)
    visit oauth_application_path(app)
    click_link "Autorisierungen"

    expect do
      click_link "Autorisieren"

      expect(page).to have_text "Autorisierungscode"
    end.to change { app.access_grants.count }.by(1)

    code = find("#authorization_code").text
    visit oauth_application_path(app)
    click_link "Autorisierungen"
    expect(page).not_to have_content code
  end

  it "creates access_token for the user" do
    skip "page.driver.post is not supported"
    app = Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri)
    grant = app.access_grants.create!(resource_owner_id: user.id, expires_in: 10, redirect_uri: redirect_uri)
    page.driver.post oauth_token_path, {client_id: app.uid, client_secret: app.secret, redirect_uri: redirect_uri, code: grant.token, grant_type: "authorization_code"}
    access_token = json["access_token"]
    expect(access_token).to be_present
    visit oauth_application_path(app)
    expect(page).to have_content access_token
  end

  context "token" do
    before do
      @app = Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri)
      Doorkeeper.configure do
        force_ssl_in_redirect_uri { false }
      end
    end

    it "might use access token without scope" do
      token = @app.access_tokens.create!(resource_owner_id: user.id)
      skip "page.driver.header is not supported"
      page.driver.header "Authorization", "Bearer #{token}"
      page.driver.get oauth_profile_path
      expect(json.keys).to eq %w[id email]
    end

    it "returns different representation for different scope" do
      token = @app.access_tokens.create!(resource_owner_id: user.id, scopes: "email name")
      skip "page.driver.header is not supported"
      page.driver.header "Authorization", "Bearer #{token}"
      page.driver.header "X-Scope", "name"
      page.driver.get oauth_profile_path
      expect(json.keys).to eq %w[id email first_name last_name nickname]
    end

    it "return error if scope is not configured on application" do
      token = @app.access_tokens.create!(resource_owner_id: user.id, scopes: "email")
      skip "page.driver.header is not supported"
      page.driver.header "Authorization", "Bearer #{token}"
      page.driver.header "X-Scope", "name"
      page.driver.get oauth_profile_path
      expect(json.keys).to eq %w[error]
      expect(page.driver.response.status).to eq 403
    end
  end

  def json
    JSON.parse(page.driver.response.body)
  end
end
