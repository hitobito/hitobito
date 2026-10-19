#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Event participation lists", js: true do
  include_context "people multiselect"

  # the typeahead updaters read the csrf meta tag, which is only rendered with forgery protection
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  let!(:event) do
    Fabricate(:course, name: "Eventus", groups: [group],
      dates: [Event::Date.new(start_at: 10.days.from_now)])
  end

  def choose_event
    find("#q").fill_in with: "Event"
    find('ul[role="listbox"] li[role="option"]', text: "Eventus").click
    expect(page).to have_select("role_type")
  end

  shared_examples "participation actions" do
    before { open_people_list }

    it "adds selected people as participants" do
      click_link("Zu Veranstaltung hinzufügen")
      click_link("Kurs", exact: true)
      choose_event
      select("Hauptleitung", from: "role_type")

      expect do
        click_button("Hinzufügen")
        expect(page).to have_content("#{count} Personen wurden erfolgreich zum Kurs 'Eventus' hinzugefügt")
      end.to change { Event::Participation.count }.by(count)

      expect(event.participations.pluck(:participant_id)).to match_array(selected.map(&:id))
    end
  end

  context "with single people selected" do
    include_context "single people selected"

    it_behaves_like "participation actions"
  end

  context "with all filtered people selected" do
    include_context "all filtered people selected"

    it_behaves_like "participation actions"
  end
end
