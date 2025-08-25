#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Translated input fields", js: true do
  before do
    Settings.application.languages = {de: "Deutsch", en: "English", fr: "Français"}
    sign_in(people(:root))
  end

  it "should show and hide inputs, display already translated languages and save all languages" do
    group = Group.first
    visit edit_group_path(group)

    # Should show all inputs after clicking translation button
    expect(page).to have_css("input[id^='group_privacy_policy_title']", count: 1)
    page.first("button[data-action='translatable-fields#toggleFields']").click
    expect(page).to have_css("input[id^='group_privacy_policy_title']", count: 3)

    # Should show languages that are filled in besides the current locale
    fill_in "group_privacy_policy_title", with: "German privacy policy title"
    expect(page).not_to have_content("Zusätzlich ausgefüllte Sprachen")
    fill_in "group_privacy_policy_title_en", with: "English privacy policy title"
    expect(page).to have_content("Zusätzlich ausgefüllte Sprachen: EN")
    fill_in "group_privacy_policy_title_fr", with: "French privacy policy title"
    expect(page).to have_content("Zusätzlich ausgefüllte Sprachen: EN, FR")

    # Should still show filled in languages after hiding the language fields again
    page.first("button[data-action='translatable-fields#toggleFields']").click
    expect(page).to have_css("input[id^='group_privacy_policy_title']", count: 1)
    expect(page).to have_content("Zusätzlich ausgefüllte Sprachen: EN, FR")

    # Should successfully save all translations
    click_button("Speichern")
    expect(page).to have_content("Gruppe #{group.name} wurde erfolgreich aktualisiert")
    expected_value = {de: "German privacy policy title", en: "English privacy policy title", fr: "French privacy policy title"}.stringify_keys
    expect(group.reload.privacy_policy_title_translations).to eql(expected_value)
  end

  it "should show errors of additional translated fields with locale suffix" do
    group = Group.first
    visit edit_group_path(group)

    # Should show attribute name without language suffix for current locale
    fill_in "group_privacy_policy_title", with: "Text" * 100
    click_button("Speichern")
    expect(page).to have_css("input[id^='group_privacy_policy_title']", count: 1)
    expect(page).to have_content("DSE/Datenschutzerklärung Titel ist zu lang (mehr als 64 Zeichen)")

    # Should show all language fields and attribute name with suffix for other locales
    page.first("button[data-action='translatable-fields#toggleFields']").click
    fill_in "group_privacy_policy_title_en", with: "Text" * 100
    click_button("Speichern")
    expect(page).to have_css("input[id^='group_privacy_policy_title']", count: 3)
    expect(page).to have_content("DSE/Datenschutzerklärung Titel ist zu lang (mehr als 64 Zeichen)")
    expect(page).to have_content("DSE/Datenschutzerklärung Titel (EN) ist zu lang (mehr als 64 Zeichen)")
  end

  it "should translate rich text inputs" do
    custom_content = CustomContent.find_by(label: "Auftrag erhalten")
    visit edit_custom_content_path(custom_content)

    page.all("button[data-action='translatable-fields#toggleFields']")[1].click(x: 10, y: 10)
    find("trix-editor#custom_content_body").set("Rich text content german {assignment-title}")
    find("trix-editor#custom_content_body_en").set("Rich text content english {assignment-title}")
    find("trix-editor#custom_content_body_fr").set("Rich text content french {assignment-title}")

    click_button("Speichern")
    expect(page).to have_content("Text #{custom_content.label} wurde erfolgreich aktualisiert")
  end
end
