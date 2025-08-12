# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "Person::CsvImport" do
  include CsvImportMacros
  let(:role) { roles(:top_leader) }
  let(:person) { people(:top_leader) }
  let(:group) { groups(:bottom_layer_one) }
  let(:file) { path(:utf8) }

  before { sign_in(person) }

  it "can preview, go back and import person" do
    visit group_people_path(group_id: group.id)
    click_link "Liste importieren"
    attach_file("CSV Datei", file)
    click_button "Hochladen"
    expect(page).to have_css "legend", text: "Aktualisierungsverhalten"
    click_button "Vorschau"
    expect(page).to have_text "Folgende Personen werden mit der Rolle Leader in die Gruppe Bottom One importiert."
    expect(page).to have_css "tr", text: "Ésaïe Gärber"
    click_button "Zurück"
    expect(page).to have_css "legend", text: "Aktualisierungsverhalten"
    click_button "Vorschau"
    click_button "Personen jetzt importieren"
    expect(page).to have_css ".alert-success", text: "1 Person (Leader) wurde erfolgreich importiert."
  end
end
