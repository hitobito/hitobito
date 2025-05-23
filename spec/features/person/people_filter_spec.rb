#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeopleController, js: true do
  let(:group) { groups(:top_layer) }

  it "may define role filter, display and edit it again" do
    member = people(:bottom_member)
    leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two)).person
    Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_two))

    obsolete_node_safe do
      sign_in_and_create_filter

      find("#filters_role_role_type_ids_#{Group::BottomLayer::Leader.id}").set(true)
      find("#filters_role_role_type_ids_#{Group::BottomLayer::Member.id}").set(true)
      fill_in("people_filter_name", with: "Bottom Layer")
      all("form .btn-toolbar").first.click_button("Suche speichern")

      expect(page).to have_selector(".table tbody tr", count: 2)
      expect(page).to have_selector("#person_#{leader.id}")
      expect(page).to have_selector("#person_#{member.id}")

      # edit the current filter
      click_link "Bottom Layer"
      click_link "Neuer Filter..."

      # roles accordion is already open
      expect(page).to have_selector(".accordion-body", count: 1)

      expect(page).to have_checked_field("filters_role_role_type_ids_#{Group::BottomLayer::Leader.id}")
      expect(page).to have_checked_field("filters_role_role_type_ids_#{Group::BottomLayer::Member.id}")

      find("#filters_role_role_type_ids_#{Group::BottomLayer::Member.id}").set(false)
      all("form .btn-toolbar").first.click_button("Suchen")

      expect(page).to have_selector(".table tbody tr", count: 1)
      expect(page).to have_selector("tr#person_#{leader.id}")

      # open the previously defined filter again
      click_link "Eigener Filter"
      click_link "Bottom Layer"

      # roles accordion is already open
      expect(page).to have_selector(".table tbody tr", count: 2)

      # open other tab
      click_link "Externe"
      expect(page).to have_no_selector(".table-striped tbody tr")
    end
  end

  context "toggling roles" do
    it "toggles roles when clicking layer" do
      obsolete_node_safe do
        sign_in_and_create_filter

        find("h4.filter-toggle", text: "Top Layer").click
        expect(page).to have_css("#roles input[name='filters[role][role_type_ids][]']:checked", count: 8)

        find("h4.filter-toggle", text: "Top Layer").click
        expect(page).to have_css("#roles input[name='filters[role][role_type_ids][]']:checked", count: 0)
      end
    end

    it "toggles roles when clicking group" do
      obsolete_node_safe do
        sign_in_and_create_filter

        find("h5.filter-toggle", text: "Top Group").click
        expect(page).to have_css("#roles input[name='filters[role][role_type_ids][]']:checked", count: 7)

        find("h5.filter-toggle", text: "Top Group").click
        expect(page).to have_css("#roles input[name='filters[role][role_type_ids][]']:checked", count: 0)
      end
    end

    it "toggles groups and layers when changing range" do
      obsolete_node_safe do
        sign_in
        visit group_people_path(group, range: "group")

        click_link "Weitere Ansichten"
        click_link "Neuer Filter..."
        expect(page).to have_content "Personen filtern"
        click_link "Rollen"

        expect(page).to have_no_selector("h4", text: "Bottom Layer")
        expect(page).to have_selector("h4", text: "Top Layer")
        expect(page).to have_selector("h5", text: "Top Layer")
        expect(page).to have_no_selector("h5", text: "Top Group")

        find("#range_deep").set(true)
        expect(page).to have_selector("h4", text: "Bottom Layer")

        find("#range_group").set(true)
        expect(page).to have_no_selector("h4", text: "Bottom Layer")
        expect(page).to have_selector("h4", text: "Top Layer")
        expect(page).to have_selector("h5", text: "Top Layer")
        expect(page).to have_no_selector("h5", text: "Top Group")

        find("#range_layer").set(true)
        expect(page).to have_no_selector("h4", text: "Bottom Layer")
        expect(page).to have_selector("h4", text: "Top Layer")
        expect(page).to have_selector("h5", text: "Top Layer")
        expect(page).to have_selector("h5", text: "Top Group")
      end
    end
  end

  context "qualifications" do
    before do
      sign_in
      visit group_people_path(group, range: "group")

      click_link "Weitere Ansichten"
      click_link "Neuer Filter..."
      expect(page).to have_content "Personen filtern"
      click_link "Qualifikationen"
    end

    it "adjusts filters when checking 'Alle jemals erteilten Qualifikationen'" do
      choose "Alle jemals erteilten Qualifikationen"
      expect(page).to have_content "Qualifikationsjahr einschränken"
      expect(page).not_to have_content "Stichdatum"
      expect(page).not_to have_field "Person hat ALLE diese Qualifikationen" # is disabled
      expect(page).to have_checked_field "Person hat mindestens EINE dieser Qualifikationen"
    end

    it "adjusts filters when checking 'Keine jemals erteilte Qualifikation'" do
      choose "Keine jemals erteilte Qualifikation"
      expect(page).not_to have_content "Qualifikationsjahr einschränken"
      expect(page).not_to have_content "Stichdatum"
      expect(page).not_to have_field "Person hat ALLE diese Qualifikationen" # is disabled
      expect(page).to have_checked_field "Person hat mindestens EINE dieser Qualifikationen"
    end

    it "adjusts filters when checking 'Abgelaufene, aber nicht gültige oder reaktivierbare Qualifikationen'" do
      choose "Keine jemals erteilte Qualifikation"
      expect(page).not_to have_content "Qualifikationsjahr einschränken"
      expect(page).not_to have_content "Stichdatum"
      expect(page).not_to have_field "Person hat ALLE diese Qualifikationen" # is disabled
      expect(page).to have_checked_field "Person hat mindestens EINE dieser Qualifikationen"
    end
  end

  context "attributes" do
    before do
      sign_in
      visit group_people_path(group, range: "layer")

      click_link "Weitere Ansichten"
      click_link "Neuer Filter..."
      expect(page).to have_content "Personen filtern"
      click_link "Felder"
    end

    it "supports filtering by specific attribute on person" do
      choose "In der aktuellen Ebene und allen darunter liegenden Ebenen und Gruppen"
      first(:button, "Suchen").click
      expect(page).to have_css "td", text: "Leader Top"
      expect(page).to have_css "td", text: "Member Bottom"
      click_link "Eigener Filter"
      click_link "Neuer Filter..."
      click_link "Felder"
      select "Nachname"
      option = select "ist genau"
      value_id = option.send(:parent)["id"].gsub("constraint", "value")
      fill_in(value_id, with: "Leader")
      first(:button, "Suchen").click
      expect(page).to have_css "td", text: "Leader Top"
      expect(page).not_to have_css "td", text: "Member Bottom"
    end

    it "removes value field when selecting blank constraint" do
      find("#attribute_filter option", text: "Nachname").click
      find(".attribute_constraint_dropdown option", text: "ist leer").click
      expect(page).not_to have_css ".attribute_value_input"
    end

    it "has country select dropdown for country attrs" do
      find("#attribute_filter option", text: "Land").click
      expect(page).to have_css ".country_select_field"
    end

    it "has integer type field for number fields" do
      find("#attribute_filter option", text: "Alter").click
      expect(page).to have_css ".integer_field"
    end

    it "has date field for date attrs" do
      find("#attribute_filter option", text: "Geburtstag").click
      expect(page).to have_css ".date_field"
    end

    it "has gender field for gender attrs" do
      find("#attribute_filter option", text: "Geschlecht").click
      expect(page).to have_css ".gender_select_field"
    end
  end

  def sign_in_and_create_filter
    sign_in
    visit group_people_path(group)
    expect(page).to have_no_selector(".table tbody tr")

    find(".dropdown-toggle", text: "Weitere Ansichten").click
    find(".dropdown-item", text: "Neuer Filter...").click
    find(".accordion-button", text: "Rollen").click

    expect(page).to have_css("#roles .label-columns input:checked", count: 0)
  end
end
