# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ApplicationMarketController do

  let(:event) { Fabricate(:course) }

  let(:group) { event.groups.first }

  let(:appl_prio_1) do
    Fabricate(:event_participation,
              event: event,
              application: Fabricate(:event_application, priority_1: event))
  end

  let(:appl_prio_2) do
    Fabricate(:event_participation,
              application: Fabricate(:event_application, priority_2: event))
  end

  let(:appl_prio_3) do
    Fabricate(:event_participation,
              application: Fabricate(:event_application, priority_3: event))
  end

  let(:appl_waiting) do
    Fabricate(:event_participation,
              application: Fabricate(:event_application, waiting_list: true),
              event: Fabricate(:course, kind: event.kind))
  end

  let(:appl_other) do
    Fabricate(:event_participation,
              application: Fabricate(:event_application))
  end
  let(:appl_other_assigned) do
    participation = Fabricate(:event_participation, active: true)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    Fabricate(:event_application, priority_2: event, participation: participation)
    participation.reload
  end

  let(:appl_participant) do
    participation = Fabricate(:event_participation, event: event, active: true)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    Fabricate(:event_application, participation: participation, priority_2: event)
    participation.reload
  end

  let(:leader) do
    participation = Fabricate(:event_participation, event: event)
    Fabricate(Event::Role::Leader.name.to_sym, participation: participation)
  end

  before do
    # init required data
    appl_prio_1
    appl_prio_2
    appl_prio_3
    appl_waiting
    appl_other
    appl_other_assigned
    appl_participant
    leader
  end


  describe "requests are mutually undoable", js: true do

    context "waiting_list" do
      it "starting from application", unstable: true do
        obsolete_node_safe do
          sign_in
          visit group_event_application_market_index_path(group.id, event.id)

          participants = find("#participants").text
          applications = find("#applications").text

          appl_id = "event_participation_#{appl_prio_1.id}"
          expect(all("#applications ##{appl_id} td").last).to have_selector(".fa-minus")

          find("#applications ##{appl_id}").click_link("Warteliste")
          fill_in("event_application_waiting_list_comment", with: "only if possible")
          find("#applications ##{appl_id} button.btn-primary").click
          skip("cannot find icon .fa-ok")
          expect(all("#applications ##{appl_id} td").last).to have_selector(".fa-ok")
          expect(all("#applications ##{appl_id} td").last).to have_selector(".fa-comment")

          find("#applications ##{appl_id}").click_link("Warteliste")
          expect(all("#applications ##{appl_id} td").last).to have_selector(".fa-minus")
          expect(all("#applications ##{appl_id} td").last).to have_no_selector(".fa-comment")

          visit group_event_application_market_index_path(group.id, event.id)

          expect(find("#participants").text).to eq(participants)
          expect(find("#applications").text).to eq(applications)
        end
      end

      it "starting from application on waiting list" do
        obsolete_node_safe do
          sign_in
          visit group_event_application_market_index_path(group.id, event.id)

          find("#waiting_list").set(true)
          click_button("Aktualisieren")

          participants = find("#participants").text
          applications = find("#applications").text

          appl_id = "event_participation_#{appl_waiting.id}"
          skip("cannot find icon .fa-ok")
          expect(all("#applications ##{appl_id} td").last).to have_selector(".fa-ok")

          find("#applications ##{appl_id}").click_link("Warteliste")

          expect(all("#applications ##{appl_id} td").last).to have_selector(".fa-minus")

          find("#applications ##{appl_id}").click_link("Warteliste")
          find("#applications ##{appl_id} button.btn-primary").click
          expect(all("#applications ##{appl_id} td").last).to have_selector(".fa-ok")
          expect(all("#applications ##{appl_id} td").last).to have_no_selector(".fa-comment")

          visit group_event_application_market_index_path(group.id, event.id, "prio[]" => 1, waiting_list: true)

          expect(find("#participants").text).to eq(participants)
          expect(find("#applications").text).to eq(applications)
        end
      end
    end

    context "participant" do
      it "starting from application" do
        obsolete_node_safe do
          sign_in
          visit group_event_application_market_index_path(group.id, event.id)

          participants = find("#participants").text
          applications = find("#applications").text

          appl_id = "event_participation_#{appl_prio_1.id}"

          all("#applications ##{appl_id} td").first.find("a").click
          expect(page).to have_no_selector("#applications ##{appl_id}")

          # first do find().should have_content to make capybara wait for animation, then all().last
          expect(find("#participants")).to have_content(appl_prio_1.person.to_s(:list))
          expect(all("#participants tr").last).to have_content(appl_prio_1.person.to_s(:list))

          all("#participants ##{appl_id} td").last.find("a").click
          expect(page).to have_no_selector("#participants ##{appl_id}")

          # first do find().should have_content to make capybara wait for animation, then all().last
          expect(find("#applications")).to have_content(appl_prio_1.person.to_s(:list))
          expect(all("#applications tr").last).to have_content(appl_prio_1.person.to_s(:list))

          visit group_event_application_market_index_path(group.id, event.id)

          expect(find("#participants").text).to eq(participants)
          expect(find("#applications").text).to eq(applications)
        end
      end

      it "starting from application on waiting list" do
        obsolete_node_safe do
          sign_in
          visit group_event_application_market_index_path(group.id, event.id)

          find("#waiting_list").set(true)
          click_button("Aktualisieren")

          participants = find("#participants").text
          applications = find("#applications").text

          appl_id = "event_participation_#{appl_waiting.id}"

          all("#applications ##{appl_id} td").first.find("a").click

          # first do find().should have_content to make capybara wait for animation, then all().last
          expect(find("#participants")).to have_content(appl_waiting.person.to_s(:list))
          expect(all("#participants tr").last).to have_content(appl_waiting.person.to_s(:list))
          expect(page).to have_no_selector("#applications ##{appl_id}")

          all("#participants ##{appl_id} td").last.find("a").click
          expect(page).to have_no_selector("#participants ##{appl_id}")

          # first do find().should have_content to make capybara wait for animation, then all().last
          expect(find("#applications")).to have_content(appl_waiting.person.to_s(:list))
          expect(all("#applications tr").last).to have_content(appl_waiting.person.to_s(:list))
          expect(all("#applications tr").last).to have_selector(".fa-minus")

          visit group_event_application_market_index_path(group.id, event.id, "prio[]" => 1, waiting_list: true)

          # once assigned, a participant is removed from the waiting list
          expect(page).to have_no_selector("#applications ##{appl_id}")

          expect(find("#participants").text).to eq(participants)
          expect(find("#applications").text).not_to eq(applications)
        end
      end

      it "starting from participant" do
        obsolete_node_safe do
          sign_in
          visit group_event_application_market_index_path(group.id, event.id)

          participants = find("#participants").text
          applications = find("#applications").text

          appl_id = "event_participation_#{appl_participant.id}"

          all("#participants ##{appl_id} td").last.find("a").click
          expect(page).to have_no_selector("#participants ##{appl_id}")

          # first do find().should have_content to make capybara wait for animation, then all().last
          expect(find("#applications")).to have_content(appl_participant.person.to_s(:list))
          expect(all("#applications tr").last).to have_content(appl_participant.person.to_s(:list))
          all("#applications ##{appl_id} td").first.find("a").click

          # first do find().should have_content to make capybara wait for animation, then all().last
          expect(find("#participants tr")).to have_content(appl_participant.person.to_s(:list))
          expect(all("#participants tr").last).to have_content(appl_participant.person.to_s(:list))
          expect(page).to have_no_selector("#applications ##{appl_id}")

          visit group_event_application_market_index_path(group.id, event.id)

          expect(find("#participants").text).to eq(participants)
          expect(find("#applications").text).to eq(applications)
        end
      end

    end
  end

  describe "popovers", js: true do
    it "opening one closes the others" do
      sign_in
      visit group_event_application_market_index_path(group.id, event.id)

      check("Prio 1")
      check("Prio 2")
      check("Prio 3")
      click_button("Aktualisieren")

      appl1_id = "event_participation_#{appl_prio_1.id}"
      expect(page).to have_selector("#applications ##{appl1_id} td .fa-minus")

      appl2_id = "event_participation_#{appl_prio_2.id}"
      expect(page).to have_selector("#applications ##{appl2_id} td .fa-minus")

      find("#applications ##{appl2_id}").click_link("Warteliste")
      expect(page).to have_selector("#applications ##{appl2_id} td .popover")

      find("#applications ##{appl1_id}").click_link("Warteliste")
      expect(page).to have_selector("#applications ##{appl1_id} td .popover")
      expect(all("#applications ##{appl2_id} td").last).to have_no_selector(".popover")
    end

    it "may be closed with cancel link" do
      sign_in
      visit group_event_application_market_index_path(group.id, event.id)

      appl1_id = "event_participation_#{appl_prio_1.id}"
      expect(page).to have_selector("#applications ##{appl1_id} td .fa-minus")

      find("#applications ##{appl1_id}").click_link("Warteliste")
      expect(page).to have_selector("#applications ##{appl1_id} td .popover")

      find("#applications ##{appl1_id}").click_link("Abbrechen")
      expect(all("#applications ##{appl1_id} td").last).to have_no_selector(".popover")
    end
  end

end
