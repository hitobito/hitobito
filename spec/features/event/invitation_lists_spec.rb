#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Event invitation lists", js: true do
  context "for single person" do
    let(:top_layer) { groups(:top_layer) }
    let(:group) { groups(:top_group) }
    let(:leader) { people(:top_leader) }
    let!(:role1) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group) }
    let!(:role2) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group) }
    let(:event_date) { Event::Date.new(start_at: 10.days.from_now) }
    let(:event) { Fabricate(:event, application_opening_at: 5.days.ago, groups: [top_layer], dates: [event_date]) }

    before do
      sign_in(leader)
    end

    it "invites single person" do
      visit simple_group_events_path(group_id: top_layer, year: event.dates.first.start_at.year)
      click_link("Eventus")
      click_link("Einladungen")
      click_link("Person einladen")
      click_link("Teilnehmer/-in")

      fill_in(id: "event_invitation_person", with: role1.person.first_name)
      find("li#autoComplete_result_0").click

      click_button("Speichern")

      expect(page).to have_content(role1.person.to_s)
      name = "#{role1.person.first_name} #{role1.person.last_name}"
      expect(page).to have_content(/Einladung für #{name} als Teilnehmer\/-in wurde erstellt./)
    end
  end

  context "with selected people" do
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

    shared_examples "invitation actions" do
      before { open_people_list }

      it "invites selected people" do
        click_link("Zu Veranstaltung hinzufügen")
        click_link("Kurs (Einladung)")
        choose_event

        expect do
          click_button("Einladen")
          expect(page).to have_content("#{count} Personen wurden erfolgreich zum Kurs 'Eventus' eingeladen")
        end.to change { Event::Invitation.count }.by(count)

        expect(event.invitations.pluck(:person_id)).to match_array(selected.map(&:id))
      end
    end

    context "with single people selected" do
      include_context "single people selected"

      it_behaves_like "invitation actions"
    end

    context "with all filtered people selected" do
      include_context "all filtered people selected"

      it_behaves_like "invitation actions"
    end
  end
end
