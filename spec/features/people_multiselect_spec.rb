#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

# Selecting everything via the "Alle n auswählen" checkbox submits ids=all, so
# every bulk action has to forward the filter of the people list in order to act
# on exactly the filtered people and not on the whole group.
describe "People multiselect with extended select all", js: true do
  let(:group) { groups(:top_group) }
  let(:user) { people(:top_leader) }
  let(:member_type) { Group::TopGroup::Member }

  let!(:members) do
    Array.new(3) { Fabricate(member_type.name.to_sym, group: group).person }
  end
  let!(:bystanders) do
    Array.new(2) { Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: group).person }
  end

  let(:filter_params) do
    {range: "group", filters: {role: {role_type_ids: member_type.type_id}}}
  end

  before do
    allow(Kaminari.config).to receive(:default_per_page).and_return(2)
    sign_in(user)
    visit group_people_path(group, **filter_params)
    select_all_filtered_people
  end

  def select_all_filtered_people
    find("#all").click
    expect(page).to have_content("2 ausgewählt")
    expect(page).to have_content("Alle 3 auswählen")
    find("label.extended_all").click
    expect(page).to have_content("3 ausgewählt")
  end

  def roles_of(people)
    Role.where(person_id: people.map(&:id))
  end

  describe "roles" do
    before { click_link("Rollen") }

    it "adds role to filtered people only" do
      click_link("Rolle hinzufügen")
      select("Secretary", from: "role_type")
      expect(page).to have_button("3 Rollen erstellen")
      click_button("3 Rollen erstellen")

      expect(page).to have_content("3 Rollen wurden erstellt")
      expect(roles_of(members).where(type: Group::TopGroup::Secretary.sti_name)).to have(3).items
      expect(roles_of(bystanders).where(type: Group::TopGroup::Secretary.sti_name)).to be_empty
    end

    it "removes roles of filtered people only" do
      members.each { |m| Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: group, person: m) }
      visit group_people_path(group, **filter_params)
      select_all_filtered_people
      click_link("Rollen")

      click_link("Rollen entfernen")
      expect(page).to have_content("Welche Rollen sollen gelöscht werden?")
      click_button("Entfernen")

      expect(page).to have_content("6 Rollen wurden entfernt")
      expect(roles_of(members)).to be_empty
      expect(roles_of(bystanders)).to have(2).items
    end

    it "moves roles of filtered people only" do
      click_link("Rollen verschieben")
      select("Secretary", from: "role_type")
      click_button("Weiter")
      click_button("Rollen verschieben")

      expect(page).to have_content("3 Rollen wurden verschoben")
      expect(roles_of(members).pluck(:type).uniq).to eq [Group::TopGroup::Secretary.sti_name]
      expect(roles_of(bystanders).pluck(:type).uniq).to eq [Group::TopGroup::LocalSecretary.sti_name]
    end
  end

  describe "tags" do
    before { click_link("Tags") }

    it "adds tags to filtered people only" do
      click_link("Tags hinzufügen")
      fill_in("tags", with: "fresh")
      click_button("Tags auf 3 Personen erstellen")
      expect(page).to have_content("Tags auf 3 Personen werden im Hintergrund erstellt")

      Delayed::Worker.new.work_off
      expect(ActsAsTaggableOn::Tagging.where(taggable_id: members.map(&:id)).count).to eq 3
      expect(ActsAsTaggableOn::Tagging.where(taggable_id: bystanders.map(&:id))).to be_empty
    end

    it "removes tags from filtered people only" do
      (members + bystanders).each { |person| person.update!(tag_list: "stale") }
      refresh

      select_all_filtered_people
      click_link("Tags")
      click_link("Tags entfernen")
      expect(page).to have_content("Welche Tags sollen gelöscht werden?")
      expect(page).to have_content("stale3")
      check("stale")
      click_button("Entfernen")
      expect(page).to have_content("Tags auf 3 Personen werden im Hintergrund entfernt")

      Delayed::Worker.new.work_off
      expect(ActsAsTaggableOn::Tagging.where(taggable_id: members.map(&:id))).to be_empty
      expect(ActsAsTaggableOn::Tagging.where(taggable_id: bystanders.map(&:id)).count).to eq 2
    end
  end

  describe "mailing list" do
    let!(:list) { Fabricate(:mailing_list, name: "Newsletter", group: group) }

    it "subscribes filtered people only" do
      click_link("Zu Abo hinzufügen")
      find("#q").fill_in with: "News"
      find('ul[role="listbox"] li[role="option"]', text: "Newsletter").click

      expect do
        click_button("Hinzufügen")
        expect(page).to have_content("3 Personen wurden erfolgreich zum Abo 'Newsletter' hinzugefügt")
      end.to change { Subscription.count }.by(3)

      expect(list.subscriptions.pluck(:subscriber_id)).to match_array(members.map(&:id))
    end
  end

  describe "events" do
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

    it "adds filtered people as participants" do
      click_link("Zu Veranstaltung hinzufügen")
      click_link("Kurs", exact: true)
      choose_event
      select("Hauptleitung", from: "role_type")

      expect do
        click_button("Hinzufügen")
        expect(page).to have_content("3 Personen wurden erfolgreich zum Kurs 'Eventus' hinzugefügt")
      end.to change { Event::Participation.count }.by(3)

      expect(event.participations.pluck(:participant_id)).to match_array(members.map(&:id))
    end

    it "invites filtered people" do
      click_link("Zu Veranstaltung hinzufügen")
      click_link("Kurs (Einladung)")
      choose_event

      expect do
        click_button("Einladen")
        expect(page).to have_content("3 Personen wurden erfolgreich zum Kurs 'Eventus' eingeladen")
      end.to change { Event::Invitation.count }.by(3)

      expect(event.invitations.pluck(:person_id)).to match_array(members.map(&:id))
    end
  end
end
