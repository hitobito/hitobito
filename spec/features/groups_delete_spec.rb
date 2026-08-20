# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe :groups_delete, type: :feature, js: true do
  let(:group) { groups(:top_group) }
  let(:user) { people(:root) }

  before { sign_in(user) }

  def open_delete_modal
    visit group_path(group)
    first(".btn-group.dropdown .dropdown-toggle").click
    click_link "Löschen"
  end

  describe "confirm_deletion modal" do
    it "displays confirmation modal from the actions dropdown" do
      open_delete_modal

      expect(page).to have_current_path(group_path(group))
      expect(page).to have_selector("#confirm-group-deletion.modal", visible: :visible)
      expect(page).to have_selector(".modal-title", text: group.name)
    end

    it "shows warning message in the modal" do
      open_delete_modal

      expect(page).to have_content("Achtung")
      expect(page).to have_content(group.name)
    end

    it "displays a text input field for confirmation" do
      open_delete_modal

      expect(page).to have_selector("input[data-action='confirm-deletion#validate']")
    end

    it "delete button is disabled by default" do
      open_delete_modal

      delete_button = find("#confirm-group-deletion a.btn-danger")
      expect(delete_button[:class]).to include("disabled")
    end

    it "enables delete button when correct group name is entered" do
      open_delete_modal
      fill_in "group-name", with: group.name

      delete_button = find("#confirm-group-deletion a.btn-danger")
      expect(delete_button[:class]).not_to include("disabled")
    end

    it "keeps delete button disabled when incorrect name is entered" do
      open_delete_modal

      fill_in "group-name", with: "Wrong Group Name"

      delete_button = find("#confirm-group-deletion a.btn-danger")
      expect(delete_button[:class]).to include("disabled")
    end

    it "keeps delete button disabled when partial name is entered" do
      open_delete_modal

      fill_in "group-name", with: group.name[0..5]

      delete_button = find("#confirm-group-deletion a.btn-danger")
      expect(delete_button[:class]).to include("disabled")
    end

    it "deletes the group when delete button is clicked with correct name" do
      open_delete_modal
      group_id = group.id

      fill_in "group-name", with: group.name
      within("#confirm-group-deletion") do
        click_link "Gruppen und Rollen definitiv löschen"
      end

      expect(page).to have_current_path(group_path(group.parent))
      expect(Group.with_deleted.find(group_id)).to be_deleted
    end

    it "correctly re-enables button when clearing and re-entering name" do
      open_delete_modal

      fill_in "group-name", with: group.name
      delete_button = find("#confirm-group-deletion a.btn-danger")
      expect(delete_button[:class]).not_to include("disabled")

      fill_in "group-name", with: ""
      expect(delete_button[:class]).to include("disabled")

      fill_in "group-name", with: group.name
      expect(delete_button[:class]).not_to include("disabled")
    end

    it "shows danger styling on delete button" do
      open_delete_modal

      delete_button = find("#confirm-group-deletion a.btn-danger")
      expect(delete_button[:class]).to include("btn-danger")
      expect(delete_button[:class]).to include("disabled")
    end
  end
end
