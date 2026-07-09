# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe :event_guest, js: true do
  subject { page }

  let(:person) { people(:top_leader) }
  let(:event) { Fabricate(:event, application_opening_at: 5.days.ago, groups: [group], guest_limit: 3) }
  let(:group) { groups(:bottom_layer_one) }

  let(:participation) do
    Event::Participation.create!(event:, person:).tap do |p|
      Fabricate(Event::Role::Participant.name.to_sym, participation: p)
    end
  end

  before do
    sign_in(current_person)
  end

  context "for themselves" do
    let(:current_person) { person }

    it "registers a guest for an event" do
      visit new_group_event_guest_path(group, event, participation)
      expect(page).to have_content("Gast hinzufügen")

      fill_in "Vorname", with: "John"
      fill_in "Nachname", with: "Johnson"
      fill_in "Haupt-E-Mail", with: "johnson@puzzle.ch"
      click_button("Weiter")

      expect(page).to have_content("Bemerkungen")
      expect(page).to have_content("Anmelden und weiteren Gast hinzufügen (max. 2)")
      fill_in "Bemerkungen", with: "foobar"
      click_button("Gast anmelden")

      expect(page).to have_content("John Johnson wurde erfolgreich als Gast hinzugefügt.")
    end
  end

  context "as event leader" do
    let!(:leader_participation) do
      Event::Participation.create!(event:, person: current_person).tap do |p|
        Fabricate(Event::Role::Leader.name.to_sym, participation: p)
      end
    end
    let(:current_person) { Fabricate(:person) }

    it "registers a guest for a participant" do
      visit new_group_event_guest_path(group, event, participation)
      expect(page).to have_content("Gast hinzufügen")

      fill_in "Vorname", with: "John"
      fill_in "Nachname", with: "Johnson"
      fill_in "Haupt-E-Mail", with: "johnson@puzzle.ch"
      click_button("Weiter")

      expect(page).to have_content("Bemerkungen")
      expect(page).to have_content("Anmelden und weiteren Gast hinzufügen (max. 2)")
      fill_in "Bemerkungen", with: "foobar"
      click_button("Gast anmelden")

      expect(page).to have_content("John Johnson wurde erfolgreich als Gast hinzugefügt.")
    end
  end

  context "as person with write access to the participant" do
    let(:current_person) { role.person }
    let(:role) do
      Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
    end

    it "registers a guest for the participant" do
      visit new_group_event_guest_path(group, event, participation)
      expect(page).to have_content("Gast hinzufügen")

      fill_in "Vorname", with: "John"
      fill_in "Nachname", with: "Johnson"
      fill_in "Haupt-E-Mail", with: "johnson@puzzle.ch"
      click_button("Weiter")

      expect(page).to have_content("Bemerkungen")
      expect(page).to have_content("Anmelden und weiteren Gast hinzufügen (max. 2)")
      fill_in "Bemerkungen", with: "foobar"
      click_button("Gast anmelden")

      expect(page).to have_content("John Johnson wurde erfolgreich als Gast hinzugefügt.")
    end
  end
end
