# frozen_string_literal: true

#  Copyright (c) 2012-2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event edit page", js: true do
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:event) { Fabricate(:course, groups: [group], contact: person) }

  before do
    sign_in
    visit edit_group_event_path(group, event)
  end

  def click_save
    all("form .btn-group").first.click_button "Speichern"
  end

  describe "contact field" do
    it "removes contact person when after removing from field" do
      expect(event.contact).to eq person

      expect(find("#event_contact").value).to eq "Top Leader"
      fill_in "Kontaktperson", with: ""
      click_save

      expect(page).to have_text "Anlass #{event.name} wurde erfolgreich aktualisiert."
      expect(event.reload.contact).to be_nil
    end
  end
end
