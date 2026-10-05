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

  let(:delete_label) { I18n.t("groups.confirm_deletion.delete") }

  def open_delete_modal
    visit group_path(group)
    first(".btn-group.dropdown .dropdown-toggle").click
    click_link "Löschen"
  end

  describe "confirm_deletion modal" do
    it "opens the modal and keeps the delete button disabled for wrong input" do
      open_delete_modal

      expect(page).to have_current_path(group_path(group))
      expect(page).to have_selector("#confirm-group-deletion.modal", visible: :visible)

      within("#confirm-group-deletion") do
        expect(page).to have_selector(".modal-title", text: group.name)
        expect(page).to have_content("Achtung")
        expect(page).to have_button(delete_label, disabled: true)

        fill_in "group-name", with: "Wrong Group Name"
        expect(page).to have_button(delete_label, disabled: true)

        fill_in "group-name", with: group.name[0..5]
        expect(page).to have_button(delete_label, disabled: true)

        find_field("group-name").send_keys(:enter)
      end

      expect(page).to have_selector("#confirm-group-deletion.modal", visible: :visible)
      expect(Group.find(group.id)).not_to be_deleted
    end

    it "deletes the group when its name is entered, ignoring case and surrounding whitespace" do
      group.update!(name: " #{group.name} ")
      open_delete_modal

      within("#confirm-group-deletion") do
        fill_in "group-name", with: "  #{group.name.strip.upcase}  "
        click_button delete_label
      end

      expect(page).to have_current_path(group_path(group.parent))
      expect(Group.with_deleted.find(group.id)).to be_deleted
    end

    it "deletes the group when Enter is pressed after entering its name" do
      open_delete_modal

      within("#confirm-group-deletion") do
        fill_in "group-name", with: group.name
        expect(page).to have_button(delete_label, disabled: false)
        find_field("group-name").send_keys(:enter)
      end

      expect(page).to have_current_path(group_path(group.parent))
      expect(Group.with_deleted.find(group.id)).to be_deleted
    end
  end
end
