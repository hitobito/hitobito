#  Copyright (c) 2012-2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Person Notes", js: true do
  subject { page }

  let(:group) { groups(:top_group) }
  let(:leader) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: group).person }
  let(:secretary) { Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: group).person }
  let(:user) { leader }
  let(:person) { people(:top_leader) }

  before do
    sign_in(user)
  end

  context "creation" do
    before do
      visit group_person_path(group_id: group.id, id: person.id)
    end

    it "adds newly created notes" do
      expect(page).to have_content("Keine Einträge gefunden")

      # open form
      find("#notes-new-button").click
      expect(page).to have_selector("#note_text")

      # submit without input
      find("#new_note button").click
      expect(page).to have_selector("#notes-error", text: "Text muss ausgefüllt werden")

      # submit with input
      expect {
        fill_in("note_text", with: "ladida")
        find("#new_note button").click
        expect(page).to have_no_content("Keine Einträge gefunden")
        expect(page).to have_selector("#notes-list .note", count: 1)
      }.to change { Note.count }.by(1)
    end
  end

  context "deletion" do
    before do
      @n1 = group.notes.create!(text: "foo", author: user)
      @n2 = group.notes.create!(text: "bar", author: user)
      visit group_path(id: group.id)
    end

    it "removes deleted notes" do
      expect(page).to have_selector("#notes-list .note", count: 2)

      expect {
        accept_confirm do
          find("#note_#{@n1.id} a[data-method=delete]").click
        end
        expect(page).to have_selector("#notes-list .note", count: 1)
      }.to change { Note.count }.by(-1)
    end
  end
end
