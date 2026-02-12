# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require "spec_helper"

describe :period_invoice_templates, js: true do
  around do |example|
    original = Settings.groups.period_invoice_templates.enabled
    Settings.groups.period_invoice_templates.enabled = true
    Rails.application.reload_routes!
    example.run
    Settings.groups.period_invoice_templates.enabled = original
    Rails.application.reload_routes!
  end

  subject { page }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }

  before { sign_in(user) }

  context "create" do
    let(:new_path) { new_group_period_invoice_template_path(group) }

    it "allows to create a period invoice template" do
      visit new_path
      expect(page).not_to have_text "Rollentypen"

      fill_in "Bezeichnung", with: "Mitgliedsrechnung"
      fill_in "Rechnungsperiode Start", with: "1.1.2020"

      click_link "Rechnungsposten hinzufügen"
      click_link "Rollen-Zählung"
      expect(page).to have_text "Rollentypen"

      fill_in "Name*", with: "Normaler Preis"
      fill_in "Preis*", with: "10"

      click_button "Rollentypen auswählen"
      expect(page).to have_content "Schliessen"
      check "Local Secretary"
      check "Secretary"
      click_button "Schliessen"

      expect(page).to have_no_content "Schliessen"
      expect(page).to have_content "Secretary, Local Secretary"

      click_button "Speichern"

      expect(page).to have_text "Sammelrechnung Mitgliedsrechnung wurde erfolgreich erstellt"
      entry = group.period_invoice_templates.first
      expect(entry).not_to be_nil
      expect(entry.items.length).to be 1
      expect(entry.items[0].name).to eq("Normaler Preis")
      expect(entry.items[0].dynamic_cost_parameters["unit_cost"]).to eq("10")
      expect(entry.items[0].dynamic_cost_parameters["role_types"]).to match_array([Group::TopGroup::Secretary.name,
        Group::TopGroup::LocalSecretary.name])
    end

    it "validates presence of items" do
      visit new_path
      expect(page).not_to have_text "Rollentypen"

      fill_in "Bezeichnung", with: "Mitgliedsrechnung"
      fill_in "Rechnungsperiode Start", with: "1.1.2020"

      click_button "Speichern"

      expect(page).to have_text "Rechnungsposten muss ausgefüllt werden"
      expect(group.period_invoice_templates.length).to be 0
    end
  end

  context "update" do
    let(:period_invoice_template) { Fabricate(:period_invoice_template) }
    let(:edit_path) { edit_group_period_invoice_template_path(group, period_invoice_template) }

    it "allows to create a period invoice template" do
      visit edit_path
      expect(page).to have_text "Rollentypen"
      expect(page).to have_text "Local Guide"

      fill_in "Bezeichnung", with: "Mitgliedsrechnung - edited"

      click_link "Entfernen"
      click_link "Rechnungsposten hinzufügen"
      click_link "Rollen-Zählung"
      expect(page).to have_text "Rollentypen"

      fill_in "Name*", with: "Normaler Preis"
      fill_in "Preis*", with: "100"

      click_button "Rollentypen auswählen"
      expect(page).to have_content "Schliessen"
      check "Local Secretary"
      check "Secretary"
      click_button "Schliessen"

      expect(page).to have_no_content "Schliessen"
      expect(page).to have_no_content "Local Guide"
      expect(page).to have_content "Secretary, Local Secretary"

      click_button "Speichern"

      expect(page).to have_text "Sammelrechnung Mitgliedsrechnung - edited wurde erfolgreich aktualisiert"
      entry = group.period_invoice_templates.first
      expect(entry).not_to be_nil
      expect(entry.items.length).to be 1
      expect(entry.items[0].name).to eq("Normaler Preis")
      expect(entry.items[0].dynamic_cost_parameters["unit_cost"]).to eq("100")
      expect(entry.items[0].dynamic_cost_parameters["role_types"]).to match_array([Group::TopGroup::Secretary.name,
        Group::TopGroup::LocalSecretary.name])
    end

    it "validates presence of items" do
      visit edit_path
      expect(page).to have_text "Rollentypen"
      expect(page).to have_text "Local Guide"

      fill_in "Bezeichnung", with: "Mitgliedsrechnung - edited"

      click_link "Entfernen"

      click_button "Speichern"

      expect(page).to have_text "Rechnungsposten muss ausgefüllt werden"
      entry = group.period_invoice_templates.first
      expect(entry).not_to be_nil
      expect(entry.items.length).to be 1
      expect(entry.items[0].name).to eq("Mitgliedsbeitrag")
      expect(entry.items[0].dynamic_cost_parameters["unit_cost"]).to be_nil
      expect(entry.items[0].dynamic_cost_parameters["role_types"]).to be_blank
    end
  end
end
