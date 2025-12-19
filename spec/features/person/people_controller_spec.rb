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
    let(:cell) { row.all("td")[3] }

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
        cell.find("a").click
        expect(page).to have_css(".popover")
      }

      it "cancel closes popover" do
        click_link "Abbrechen"
        expect(page).to have_no_css(".popover")
      end

      it "changes role" do
        select "Leader", from: "Rolle"

        click_button "Speichern"
        expect(page).to have_no_css(".popover")
        expect(cell).to have_text "Leader"
      end

      it "changes role and group" do
        select "Group 111", from: "Gruppe"
        expect(page).to have_select "Rolle", selected: "", options: ["", "No Permissions", "Leader"]
        select "No Permissions", from: "Rolle"
        click_button "Speichern"
        expect(page).to have_no_css(".popover")
        expect(cell).to have_text "No Permissions"
      end

      it "informs about missing type selection" do
        select "Group 111", from: "Gruppe"
        expect(page).to have_select "Rolle", selected: "", options: ["", "No Permissions", "Leader"]
        fill_in("role_label", with: "dummy")
        click_button "Speichern"
        expect(page).to have_selector(".popover .alert-danger", text: "Rolle muss ausgefüllt werden")

        select "Group 111", from: "Gruppe"
        expect(page).to have_select "Rolle", selected: "", options: ["", "No Permissions", "Leader"]
        select "Leader", from: "Rolle"
        click_button "Speichern"
        expect(cell).to have_text "Leader"
      end
    end
  end

  context "picture upload" do
    let(:logo) { Rails.root.join("spec", "fixtures", "files", "images", "logo.png") }
    let(:person) { people(:top_leader) }

    it "does not throw error when uploading picute and selecting remove_picture at the same time" do
      person.picture.attach(Rack::Test::UploadedFile.new(logo))
      sign_in(person)
      visit edit_group_person_path(group_id: groups(:top_group), id: person.id)

      expect do
        check "Aktuelles Foto entfernen"
        all("button", text: "Speichern").first.click
        attach_file("person_picture", Rails.root.join("spec", "fixtures", "files", "images", "logo.png"))
      end.not_to raise_error
    end
  end
end
