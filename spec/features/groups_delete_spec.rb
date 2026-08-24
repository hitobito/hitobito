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
    it "renders modal content and a disabled delete button" do
      open_delete_modal

      expect(page).to have_current_path(group_path(group))
      expect(page).to have_selector("#confirm-group-deletion.modal", visible: :visible)
      expect(page).to have_selector(".modal-title", text: group.name)
      expect(page).to have_content("Achtung")
      expect(page).to have_content(group.name)
      expect(page).to have_selector("input[data-action='confirm-deletion#validate']")
      within("#confirm-group-deletion") do
        expect(page).to have_button(delete_label, disabled: true)
      end
    end

    it "toggles delete button only for an exact group-name match" do
      open_delete_modal
      delete_button = find("#confirm-group-deletion button.btn-danger")

      expect(delete_button).to be_disabled

      fill_in "group-name", with: "Wrong Group Name"
      expect(delete_button).to be_disabled

      fill_in "group-name", with: group.name[0..5]
      expect(delete_button).to be_disabled

      fill_in "group-name", with: ""
      expect(delete_button).to be_disabled

      fill_in "group-name", with: group.name
      expect(delete_button).not_to be_disabled
      within("#confirm-group-deletion") do
        click_button delete_label
      end

      expect(page).to have_current_path(group_path(group.parent))
      expect(Group.with_deleted.find(group.id)).to be_deleted
    end
  end
end
