#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Role lists", js: true do
  include_context "people multiselect"

  shared_examples "role actions" do
    before do
      open_people_list
      click_link("Rollen")
    end

    it "adds role to selected people only" do
      click_link("Rolle hinzufügen")
      select("Secretary", from: "role_type")
      expect(page).to have_button("#{count} Rollen erstellen")
      show_unpaginated_people_list
      click_button("#{count} Rollen erstellen")

      expect(page).to have_content("#{count} Rollen wurden erstellt")
      selected.each do |person|
        expect(page).to have_css("tr#person_#{person.id} td p", text: "Secretary")
      end
      expect(roles_of(selected).where(type: Group::TopGroup::Secretary.sti_name)).to have(count).items
      expect(roles_of(unselected).where(type: Group::TopGroup::Secretary.sti_name)).to be_empty
    end

    it "removes roles of selected people only" do
      members.each { |m| Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: group, person: m) }
      unselected_roles_count = roles_of(unselected).count
      open_people_list
      click_link("Rollen")

      click_link("Rollen entfernen")
      expect(page).to have_content("Welche Rollen sollen gelöscht werden?")
      show_unpaginated_people_list
      click_button("Entfernen")

      expect(page).to have_content("#{count * 2} Rollen wurden entfernt")
      selected.each { |person| expect(page).not_to have_content(person.to_s) }
      expect(roles_of(selected)).to be_empty
      expect(roles_of(unselected)).to have(unselected_roles_count).items
    end

    it "moves roles of selected people only" do
      click_link("Rollen verschieben")
      select("Secretary", from: "role_type")
      click_button("Weiter")
      show_unpaginated_people_list
      click_button("Rollen verschieben")

      expect(page).to have_content("#{count} Rollen wurden verschoben")
      selected.each do |person|
        expect(page).to have_css("tr#person_#{person.id} td p", text: "Secretary")
        expect(page).not_to have_css("tr#person_#{person.id} td p", text: "Member")
      end
      expect(roles_of(selected).pluck(:type).uniq).to eq [Group::TopGroup::Secretary.sti_name]
      expect(roles_of(unselected).pluck(:type)).not_to include(Group::TopGroup::Secretary.sti_name)
    end
  end

  context "with single people selected" do
    include_context "single people selected"

    it_behaves_like "role actions"
  end

  context "with all filtered people selected" do
    include_context "all filtered people selected"

    it_behaves_like "role actions"
  end

  context "with deselected role types" do
    include_context "single people selected"

    let!(:leader) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: group).person }
    let(:selected) { members.first(2) + [leader] }
    let(:filter_params) { {range: "group"} } # unfiltered, so the leader is listed

    before do
      open_people_list
      click_link("Rollen")
    end

    it "removes only roles of the types left checked" do
      click_link("Rollen entfernen")
      expect(page).to have_content("Welche Rollen sollen gelöscht werden?")

      find("input[name='role[types][Group::TopGroup::Member]']").set(false)
      show_unpaginated_people_list
      click_button("Entfernen")

      expect(page).to have_content("Eine Rolle wurde entfernt")
      members.first(2).each { |person| expect(page).to have_css("tr#person_#{person.id}") }
      expect(page).not_to have_css("tr#person_#{leader.id}")
      expect(roles_of(members.first(2))).to have(2).items
      expect(roles_of([leader])).to be_empty
    end

    it "moves only roles of the types left checked" do
      click_link("Rollen verschieben")

      select "Toppers", from: "role_group_id" # change so role types reload
      select "TopGroup", from: "role_group_id"

      select("Secretary", from: "role_type")
      click_button("Weiter")

      find("input[name='role[types][Group::TopGroup::Leader]']").set(false)
      show_unpaginated_people_list
      click_button("Rollen verschieben")

      expect(page).to have_content("2 Rollen wurden verschoben")
      expect(page).to have_css("tr#person_#{leader.id} td p", text: "Leader")
      expect(roles_of([leader]).pluck(:type)).to eq [Group::TopGroup::Leader.sti_name]
    end
  end
end
