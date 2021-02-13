# encoding: utf-8

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
        expect(page).to have_css("#roles input:checked", count: 6)

        find("h4.filter-toggle", text: "Top Layer").click
        expect(page).to have_css("#roles input:checked", count: 0)
      end
    end

    it "toggles roles when clicking group" do
      obsolete_node_safe do
        sign_in_and_create_filter

        find("h5.filter-toggle", text: "Top Group").click
        expect(page).to have_css("#roles input:checked", count: 5)

        find("h5.filter-toggle", text: "Top Group").click
        expect(page).to have_css("#roles input:checked", count: 0)
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

  def sign_in_and_create_filter
    sign_in
    visit group_people_path(group)
    expect(page).to have_no_selector(".table tbody tr")

    click_link "Weitere Ansichten"
    click_link "Neuer Filter..."
    click_link "Rollen"

    expect(page).to have_css("#roles .label-columns input:checked", count: 0)
  end
end
