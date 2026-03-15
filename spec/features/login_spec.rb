# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe :login, js: true do
  let(:password) { "cNb@X7fTdiU4sWCMNos3gJmQV_d9e9" }
  let(:nickname) { "foobar" }
  let(:person) { people(:bottom_member).tap { |p| p.update!(password: password, nickname: "foobar") } }

  around do |example|
    old_attrs = Person.devise_login_id_attrs.dup
    example.run
    Person.devise_login_id_attrs = old_attrs
  end

  it "allows login with email" do
    visit new_person_session_path
    fill_in "Haupt-E-Mail", with: person.email
    fill_in "Passwort", with: password
    click_button "Anmelden"

    expect(page).to have_link "Abmelden"
    expect(page).to have_selector(".content-header h1", text: person.full_name)
  end

  it "allows to reveal password" do
    visit new_person_session_path

    password_field = find("#person_password")
    expect(password_field[:type]).to eq "password"
    expect(page).to have_css(".fa-eye")
    expect(page).not_to have_css(".fa-eye-slash")

    find(".fa-eye").click

    expect(password_field[:type]).to eq "text"
    expect(page).to have_css(".fa-eye-slash")
    expect(page).not_to have_css(".fa-eye")

    find(".fa-eye-slash").click

    expect(password_field[:type]).to eq "password"
    expect(page).to have_css(".fa-eye")
  end

  it "does not allow login with nickname" do
    visit new_person_session_path
    fill_in "Haupt-E-Mail", with: person.nickname
    fill_in "Passwort", with: password
    click_button "Anmelden"

    expect(page).to have_selector("#flash .alert.alert-danger", text: "Ungültige Anmeldedaten.")
    expect(page).to have_current_path(new_person_session_path)
  end

  it "does allow login with nickname if nickname is whitelisted in Person#devise_login_id_attrs" do
    Person.devise_login_id_attrs << :nickname
    visit new_person_session_path
    fill_in "Haupt-E-Mail", with: person.nickname
    fill_in "Passwort", with: password
    click_button "Anmelden"

    expect(page).to have_link "Abmelden"
    expect(page).to have_selector(".content-header h1", text: person.full_name)
  end

  it "preserves the requested login locale when redirecting to a stored path" do
    source_locale, requested_locale = Settings.application.languages.keys.map(&:to_s).first(2)
    skip "requires at least two configured locales" if requested_locale.blank?

    visit "/#{source_locale}/groups/#{person.primary_group_id}"
    expect(page).to have_current_path("/#{source_locale}/users/sign_in")

    visit "/#{requested_locale}/users/sign_in"
    fill_in "person_login_identity", with: person.email
    fill_in "person_password", with: password
    find("form.new_person [type='submit']").click

    expect(page).to have_current_path("/#{requested_locale}/groups/#{person.primary_group_id}")
  end

  it "preserves the requested login locale when stored path has query params" do
    source_locale, requested_locale = Settings.application.languages.keys.map(&:to_s).first(2)
    skip "requires at least two configured locales" if requested_locale.blank?

    visit "/#{source_locale}/groups/#{person.primary_group_id}?foo=bar"
    expect(page).to have_current_path("/#{source_locale}/users/sign_in")

    visit "/#{requested_locale}/users/sign_in"
    fill_in "person_login_identity", with: person.email
    fill_in "person_password", with: password
    find("form.new_person [type='submit']").click

    expect(page).to have_current_path("/#{requested_locale}/groups/#{person.primary_group_id}?foo=bar")
  end

  it "preserves the requested login locale when stored path is absolute" do
    source_locale, requested_locale = Settings.application.languages.keys.map(&:to_s).first(2)
    skip "requires at least two configured locales" if requested_locale.blank?
    target_group_id = person.primary_group_id
    target_person_id = person.id
    visit "/#{source_locale}/users/sign_in"
    base_uri = URI.parse(current_url)
    absolute_target = "#{base_uri.scheme}://#{base_uri.host}:#{base_uri.port}" \
      "/#{source_locale}/groups/#{target_group_id}/people/#{target_person_id}.html"

    visit absolute_target
    expect(page).to have_current_path("/#{source_locale}/users/sign_in")

    visit "/#{requested_locale}/users/sign_in"
    fill_in "person_login_identity", with: person.email
    fill_in "person_password", with: password
    find("form.new_person [type='submit']").click

    expect(page).to have_current_path("/#{requested_locale}/groups/#{target_group_id}/people/#{target_person_id}.html")
  end

  it "preserves the login locale even when sign_in post is unlocalized" do
    source_locale, requested_locale = Settings.application.languages.keys.map(&:to_s).first(2)
    skip "requires at least two configured locales" if requested_locale.blank?

    visit "/#{source_locale}/groups/#{person.primary_group_id}"
    expect(page).to have_current_path("/#{source_locale}/users/sign_in")

    visit "/#{requested_locale}/users/sign_in"
    page.execute_script <<~JS
      document.querySelector('form.new_person').setAttribute('action', '/users/sign_in?locale=#{requested_locale}')
    JS
    fill_in "person_login_identity", with: person.email
    fill_in "person_password", with: password
    find("form.new_person [type='submit']").click

    expect(page).to have_current_path("/#{requested_locale}/groups/#{person.primary_group_id}")
  end
end
