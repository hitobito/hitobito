#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::InvitationListsController, js: true do
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

  it "invite single person" do
    visit simple_group_events_path(group_id: top_layer, id: event)
    click_link("Eventus")
    click_link("Einladungen")
    click_link("Person einladen")
    click_link("Teilnehmer/-in")

    fill_in(id: "event_invitation_person", with: role1.person.first_name)
    find("li#autoComplete_result_0").click

    click_button("Speichern")

    expect(page).to have_content(role1.person.to_s)
    expect(page).to have_content(/Einladung für #{role1.person.first_name} #{role1.person.last_name} als Teilnehmer\/-in wurde erstellt./)
  end

  xit "mass-invite" do
    visit group_people_path(top_layer)
    click_link("Weitere Ansichten")
    click_link("Gesamte Ebene")
    find("input#all").click
    click_link("Zu Veranstaltung hinzufügen")
    click_link("Anlass (Einladung)")

    expect(page).to have_content("Personen zu einem Anlass einladen")
    fill_in(id: "q", with: event.name)

    dropdown = find('ul[role="listbox"]')
    expect(dropdown).to have_content(event.name)
    find('ul[role="listbox"] li[role="option"]', text: event.name).click

    find("select#role_type option")
    # still broken: select never gets populated in tests,
    # but works for manual tests

    click_button("Einladen")

    expect(page).to have_content(/erfolgreich zum Anlass #{event.name} eingeladen/)
  end

  xit "download invitation list" do
    # Might be nice to add, but
    # there seems to be no feature specs with a download
    # so I have no idea where to start
  end
end
