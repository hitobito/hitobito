# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeopleController, js: true do
  subject { page }

  context "inline editing of role" do
    let(:group) { groups(:bottom_layer_one) }
    let(:row) { find("#content table.table").all("tr").find { |row| row.text =~ /Member Bottom/ } }
    let(:cell) { row.all("td")[2] }

    before do
      sign_in(user)
      visit group_people_path(group_id: group.id)
      expect(cell).to have_text "Member"
    end

    context "without permission" do
      let(:user) { people(:bottom_member) }

      it "does not render edit link" do
        expect(cell).to have_no_link "Bearbeiten"
      end
    end

    context "with permission" do
      let(:user) { people(:top_leader) }

      before {
        within(cell) {
          skip "Unable to find Bearbeiten"
          click_link "Bearbeiten"
        }
      }

      it "cancel closes popover" do
        obsolete_node_safe do
          click_link "Abbrechen"
          expect(page).to have_no_css(".popover")
        end
      end

      it "changes role" do
        obsolete_node_safe do
          find("#role_type_select #role_type").click
          find("#role_type_select #role_type").find("option", text: "Leader").click

          click_button "Speichern"
          expect(page).to have_no_css(".popover")
          expect(cell).to have_text "Leader"
        end
      end

      it "changes role and group" do
        obsolete_node_safe do
          find("#role_group_id_chosen #role_type").click
          find("#role_group_id_chosen #role_type").find("option", text: "Group 111").click

          find("#role_type_select #role_type").click
          find("#role_type_select #role_type").find("option", text: "Leader").click
          click_button "Speichern"
          expect(cell).to have_text "Group 111"
        end
      end

      it "informs about missing type selection" do
        obsolete_node_safe do
          find("#role_group_id_chosen #role_type").click
          find("#role_group_id_chosen #role_type").find("option", text: "Group 111").click
          fill_in("role_label", with: "dummy")

          click_button "Speichern"
          expect(page).to have_selector(".popover .alert-danger", text: "Rolle muss ausgefüllt werden")

          find("#role_type_select #role_type").click
          find("#role_type_select #role_type").find("option", text: "Leader").click
          click_button "Speichern"
          expect(cell).to have_text "Group 111"
        end
      end
    end
  end
end
