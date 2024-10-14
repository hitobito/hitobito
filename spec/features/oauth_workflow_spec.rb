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

  def json
    JSON.parse(page.driver.response.body)
  end
end
