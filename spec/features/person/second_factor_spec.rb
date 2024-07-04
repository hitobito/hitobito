# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe "second factor" do
  let(:person) do
    person = people(:bottom_member)
    person.update_columns(confirmed_at: 1.hour.ago, encrypted_password: "something", encrypted_two_fa_secret: "something")
    person
  end

  before do
    sign_in(person)
    visit person_path(person)
  end

  it "rests second factor" do
    click_on "Login"
    click_on "Zwei-Faktor-Authentifizierung zurücksetzen"
    expect(page).to have_content "Du wirst beim nächsten Login aufgefordert, " \
      "Zwei-Faktor-Authentifizierung erneut einzurichten"
    click_on "Login"
    expect(page).not_to have_link "Zwei-Faktor-Authentifizierung zurücksetzen"
    expect(page).to have_link "Zwei-Faktor-Authentifizierung einrichten"
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
