#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Translated input fields", js: true do
  let(:group) { groups(:bottom_layer_one) }

  before do
    @cached_languages = Settings.application.languages
    Settings.application.languages = {de: "Deutsch", en: "English", fr: "Français"}
    sign_in(people(:top_leader))
    visit edit_group_path(group)
  end

  after do
    Settings.application.languages = @cached_languages
  end

  it "should show and hide inputs, display already translated languages and save all languages" do
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

  it "should automatically show all language fields if a validation of not current locale fails" do
    page.first("button[data-action='translatable-fields#toggleFields']").click
    fill_in "group_privacy_policy_title_en", with: "Text" * 20
    click_button("Speichern")
    expect(page).to have_css("input[id^='group_privacy_policy_title']", count: 3)
    expect(page).to have_content("DSE/Datenschutzerklärung Titel (EN) ist zu lang (mehr als 64 Zeichen)")
  end
end
