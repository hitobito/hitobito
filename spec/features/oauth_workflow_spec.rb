# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe "OauthWorkflow" do
  let(:user) { people(:top_leader) }
  let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
  let(:app) { Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri) }

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

  context "within ui" do
    before do
      visit oauth_application_path(app)
      click_link "Autorisierungen"
    end

    it "creates access_grant with consent screen" do
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

    it "creates access_grant and skips consent screen" do
      app.update!(skip_consent_screen: true)
      expect do
        click_link "Autorisieren"
        expect(page).to have_text "Autorisierungscode"
        expect(page).not_to have_text "Autorisierung erforderlich"
      end.to change { app.access_grants.count }.by(1)
    end
  end
end
