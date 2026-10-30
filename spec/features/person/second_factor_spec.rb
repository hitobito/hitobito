# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe "second factor" do
  let(:person) do
    person = people(:bottom_member)
    person.update_columns(confirmed_at: 1.hour.ago, encrypted_password: "something",
      encrypted_two_fa_secret: "something")
    person
  end

  before do
    sign_in(person)
    visit person_path(person)
  end

  it "sets up second factor" do
    click_on "Login"
    expect(page).to have_link("Zwei-Faktor-Authentifizierung", count: 2)
    click_on "Zwei-Faktor-Authentifizierung einrichten"
    expect(page).to have_content "Bitte scanne den QR-Code"
    expect(page).to have_css(".qr-code img")
  end

  it "disables second factor" do
    click_on "Login"
    click_on "Zwei-Faktor-Authentifizierung deaktivieren"
    expect(page).to have_content "Zwei-Faktor-Authentifizierung erfolgreich deaktiviert"
    click_on "Login"
    expect(page).not_to have_link "Zwei-Faktor-Authentifizierung deaktivieren"
    expect(page).to have_link "Zwei-Faktor-Authentifizierung einrichten"
  end
end
