#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Tag lists", js: true do
  include_context "people multiselect"

  shared_examples "tag actions" do
    before do
      open_people_list
      click_link("Tags")
    end

    it "adds tags to selected people only" do
      click_link("Tags hinzufügen")
      fill_in("tags", with: "fresh")
      click_button("Tags auf #{count} Personen erstellen")
      expect(page).to have_content("Tags auf #{count} Personen werden im Hintergrund erstellt")

      Delayed::Worker.new.work_off
      expect(taggings_of(selected).count).to eq count
      expect(taggings_of(unselected)).to be_empty
    end

    it "removes tags from selected people only" do
      (members + bystanders).each { |person| person.update!(tag_list: "stale") }
      open_people_list
      click_link("Tags")

      click_link("Tags entfernen")
      expect(page).to have_content("Welche Tags sollen gelöscht werden?")
      expect(page).to have_content("stale#{count}")
      check("stale")
      click_button("Entfernen")
      expect(page).to have_content("Tags auf #{count} Personen werden im Hintergrund entfernt")

      Delayed::Worker.new.work_off
      expect(taggings_of(selected)).to be_empty
      expect(taggings_of(unselected).count).to eq unselected.size
    end
  end

  context "with single people selected" do
    include_context "single people selected"

    it_behaves_like "tag actions"
  end

  context "with all filtered people selected" do
    include_context "all filtered people selected"

    it_behaves_like "tag actions"
  end
end
