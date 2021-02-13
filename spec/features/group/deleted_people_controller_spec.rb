# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.


require "spec_helper"


describe Group::DeletedPeopleController, js: true do

  subject { page }

  context "inline creation of role" do

    let(:group) { groups(:bottom_layer_one) }
    let(:row)   { find("#content table.table").all("tr").last }
    let(:cell)  { row.all("td")[2] }
    let(:user) { people(:top_leader) }

    before do
      Fabricate(Group::BottomLayer::Member.name.to_sym,
                group: groups(:bottom_layer_one),
                created_at: 1.year.ago,
                deleted_at: 1.month.ago)
      Fabricate(Group::BottomGroup::Leader.name.to_sym,
                group: groups(:bottom_group_one_one_one),
                created_at: 1.year.ago,
                deleted_at: 1.month.ago)

      sign_in(user)
      visit group_deleted_people_path(group_id: group.id)
      within(cell) { click_link "Bearbeiten" }
    end


    it "cancel closes popover" do
      obsolete_node_safe do
        click_link "Abbrechen"
        expect(page).to have_no_css(".popover")
      end
    end

    it "creates role" do
      obsolete_node_safe do
        find("#role_type_select a.chosen-single").click
        find("#role_type_select ul.chosen-results").find("li", text: "Leader").click

        click_button "Speichern"
        expect(page).to have_no_css(".popover")
        expect(cell).to have_text "Leader"
      end
    end

    it "informs about missing type selection" do
      obsolete_node_safe do
        skip "undefined method `map' for nil:NilClass"
        find("#role_group_id_chosen a.chosen-single").click
        find("#role_group_id_chosen ul.chosen-results").find("li", text: "Group 12").click
        fill_in("role_label", with: "dummy")
        click_button "Speichern"
        expect(page).to have_selector(".popover .alert-error", text: "Rolle muss ausgefüllt werden")

        find("#role_type_select a.chosen-single").click
        find("#role_type_select ul.chosen-results").find("li", text: "Leader").click
        click_button "Speichern"
        expect(cell).to have_text "Group 12"
      end
    end
  end

end
