# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "BlocklistEntries", js: true do
  let!(:person) { Fabricate(:person, first_name: "Maximilian", last_name: "Blockus", birthday: "1980-01-15") }

  before { sign_in(people(:top_leader)) }

  it "blocklists a person without roles found by search" do
    visit new_blocklist_entry_path

    find("#blocklist_entry_person").fill_in with: "Blockus"
    sleep 0.5 # to avoid race condition in remote-typeahead
    find('ul[role="listbox"] li[role="option"]', text: "Maximilian Blockus").click

    expect do
      all(:button, "Speichern").last.click
      expect(page).to have_content "Die Person wurde auf die Ausschlussliste gesetzt."
    end.to change { BlocklistEntry.count }.by(1)

    expect(page).to have_link("Maximilian Blockus", href: person_path(person))
    expect(Person.new(first_name: "Maximilian", last_name: "Blockus", birthday: "1980-01-15")).not_to be_valid
  end
end
