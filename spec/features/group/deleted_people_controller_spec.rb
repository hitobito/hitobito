#  Copyright (c) 2017, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::DeletedPeopleController, js: true do
  subject { page }

  context "inline creation of role" do
    let(:group) { groups(:bottom_layer_one) }
    let(:row) { find("#content table.table").all("tr").last }
    let(:cell) { row.all("td")[2] }
    let(:user) { people(:top_leader) }

    before do
      Fabricate(Group::BottomLayer::Member.name.to_sym,
        group: groups(:bottom_layer_one),
        start_on: 1.year.ago,
        end_on: 1.month.ago)
      Fabricate(Group::BottomGroup::Leader.name.to_sym,
        group: groups(:bottom_group_one_one_one),
        start_on: 1.year.ago,
        end_on: 1.month.ago)

      sign_in(user)
      visit group_deleted_people_path(group_id: group.id)
      within(cell) { click_link "Bearbeiten" }
    end

    it "cancel closes popover" do
      expect(page).to have_css(".popover")
      click_link "Abbrechen"
      expect(page).to have_no_css(".popover")
    end

    it "creates role" do
      find("#role_type_select #role_type").click
      find("#role_type_select #role_type").find("option", text: "Leader").click

      click_button "Speichern"
      expect(page).to have_no_css(".popover")
      expect(cell).to have_text "Leader"
    end

    it "informs about missing type selection" do
      find("#role_group_id").click
      find("#role_group_id").find("option", text: "Group 12").click
      fill_in("role_label", with: "dummy")
      click_button "Speichern"

      expect(page).to have_selector(".popover .alert-danger", text: "Rolle muss ausgefüllt werden")

      find("#role_type_select").click
      find("#role_type_select").find("option", text: "Leader").click
      click_button "Speichern"
      expect(cell).to have_text "Group 12"
    end
  end
end
