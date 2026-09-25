# frozen_string_literal: true

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailingListsController, js: true do
  let(:user) { people(:top_leader) }
  let(:list) { mailing_lists(:leaders) }

  before { sign_in(user) }

  def select_preferred_label(name)
    10.times do
      find("#mailing_list_preferred_labels-ts-control").click
      break if page.has_css?(".ts-dropdown-content .option", text: name, wait: 0.5)
    end
    find(".ts-dropdown-content .option", text: name).click
  end

  context "index" do
    before { visit group_mailing_lists_path(list.group) }

    subject(:list_row) { find("tr", id: "mailing_list_#{list.id}") }

    context "as user who may show list" do
      let(:user) { people(:top_leader) }

      it "renders list name as link if current_user can show" do
        expect(list_row).to have_selector "td strong a", text: list.name
      end
    end
  end

  it "removes a preferred_labels category from existing mailing list" do
    list.update(preferred_labels: %w[private work])
    visit edit_group_mailing_list_path(list.group, list)
    click_link("Mailing-Liste (E-Mail)")
    expect(page).to have_link "Mailing-Liste (E-Mail)", class: "active"

    find(".item", text: "Privat").find(".remove").click
    expect(page).to have_no_selector(".item", text: "Privat")

    click_button "Speichern"
    expect(page).to have_content "erfolgreich aktualisiert"

    expect(list.reload.preferred_labels).to eq %w[work]
  end

  it "adds a preferred_labels category to a new mailing list" do
    visit new_group_mailing_list_path(list.group)
    fill_in "Name", with: "test"
    click_link("Mailing-Liste (E-Mail)")
    fill_in "Mailinglisten Adresse", with: "test"

    select_preferred_label("Privat")
    expect(page).to have_selector ".item", text: "Privat"

    click_button "Speichern"
    expect(page).to have_content "erfolgreich erstellt"

    expect(MailingList.find_by(name: "test").preferred_labels).to eq %w[private]
  end

  it "adds two preferred_labels categories to existing mailing list" do
    visit edit_group_mailing_list_path(list.group, list)
    click_link("Mailing-Liste (E-Mail)")

    select_preferred_label("Privat")
    expect(page).to have_selector ".item", text: "Privat"

    select_preferred_label("Arbeit")
    expect(page).to have_selector ".item", text: "Arbeit"

    click_button "Speichern"
    expect(page).to have_content "erfolgreich aktualisiert"

    expect(list.reload.preferred_labels).to eq %w[private work]
  end

  describe "configurable list", :js do
    it "can set opt_in on new list" do
      visit new_group_mailing_list_path(list.group)
      expect(page).to have_field "Niemand", checked: true
      expect(page).not_to have_text "Personen sind standardmässig"
      choose "Nur konfigurierte Abonnenten"
      expect(page).to have_text "Personen sind standardmässig"
      choose "Abgemeldet (opt-in)"
      fill_in "Name", with: "test"
      click_button "Speichern"
      expect(page).to have_content "Abonnenten müssen sich selbst an/abmelden"
      click_link "Abonnenten"
      expect(page).to have_css ".alert.alert-info", text: "Nur die hier konfigurierten Personen " \
        "dürfen sich selbst an-/abmelden und sind standardmässig ab-gemeldet."
    end

    it "can set opt_out on existing list" do
      visit edit_group_mailing_list_path(list.group, list)
      expect(page).to have_field "Alle", checked: true
      expect(page).not_to have_text "Personen sind standardmässig"

      choose "Nur konfigurierte Abonnenten"
      expect(page).to have_field "Angemeldet (opt-out)"
      expect(page).to have_text "Personen sind standardmässig"

      choose "Angemeldet (opt-out)"
      click_button "Speichern"
      expect(page).to have_content "Abonnenten dürfen sich selbst an/abmelden"
      click_link "Abonnenten"
      expect(page).to have_css ".alert.alert-info", text: "Nur die hier konfigurierten Personen " \
        "dürfen sich selbst an-/abmelden und sind standardmässig an-gemeldet."
    end
  end
end
