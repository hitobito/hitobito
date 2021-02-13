#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Person Autocomplete", js: true do
  subject { page }

  let(:group) { groups(:top_group) }

  it "knows about visibility of dropdown menu" do
    skip "Expected to find text 'Person hinzufügen'"
    obsolete_node_safe do
      sign_in
      visit root_path
      expect(page).to have_content("TopGroup")
      expect(page).to have_content("Personen")
      click_link "Personen"
      is_expected.to have_content " Person hinzufügen"
      click_link "Person hinzufügen"
      is_expected.to have_content "Person hinzufügen"
    end
  end

  context "highlights content in typeahead" do
    it "for non-existing queries" do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group)
        fill_in "Person", with: "gcxy"
        expect(page).to have_no_selector(".typeahead.dropdown-menu")
      end
    end

    it "for regular queries" do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group)

        fill_in "Person", with: "Top"
        expect(page).to have_selector(".typeahead.dropdown-menu li", text: "Top Leader")
        expect(find(".typeahead.dropdown-menu li")).to have_selector("strong", text: "Top")
      end
    end

    it "for two word queries" do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: {type: "Group::TopGroup::Leader"})

        fill_in "Person", with: "Top Super"

        expect(page).to have_selector(".typeahead.dropdown-menu li", text: "Top Leader")
        expect(find(".typeahead.dropdown-menu li")).to have_selector("strong", text: "Top")
        expect(find(".typeahead.dropdown-menu li")).to have_selector("strong", text: "Super")
      end
    end

    it "for queries with weird spaces" do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: {type: "Group::TopGroup::Leader"})

        fill_in "Person", with: "Top  Super "

        expect(page).to have_selector(".typeahead.dropdown-menu li", text: "Top Leader")
        expect(find(".typeahead.dropdown-menu li")).to have_selector("strong", text: "Top")
        expect(find(".typeahead.dropdown-menu li")).to have_selector("strong", text: "Super")
      end
    end

    it "saves content from typeahead" do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: {type: "Group::TopGroup::Leader"})

        # search name only
        fill_in "Person", with: "Top"
        expect(find(".typeahead.dropdown-menu li")).to have_content "Top Leader"
        find(".typeahead.dropdown-menu li").click

        all("form .btn-toolbar").first.click_button "Speichern"
        is_expected.to have_content "Rolle Leader für Top Leader in TopGroup wurde erfolgreich erstellt."
      end
    end
  end
end
