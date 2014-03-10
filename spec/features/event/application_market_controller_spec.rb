# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

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
    participation = Fabricate(:event_participation)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    Fabricate(:event_application, priority_2: event, participation: participation)
    participation
  end

  let(:appl_participant)  do
    participation = Fabricate(:event_participation, event: event)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    Fabricate(:event_application, participation: participation, priority_2: event)
    participation
  end

  let(:leader)  do
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


  describe 'requests are mutually undoable', js: true do

    context 'waiting_list' do
      it 'starting from application' do
        obsolete_node_safe do
          sign_in
          visit group_event_application_market_index_path(group.id, event.id)

          @participants = find('#participants').text
          @applications = find('#applications').text

          appl_id = "event_participation_#{appl_prio_1.id}"
          all("#applications ##{appl_id} td").last.should have_selector('.icon-minus')

          find("#applications ##{appl_id}").click_link('Warteliste')
          all("#applications ##{appl_id} td").last.should have_selector('.icon-ok')

          find("#applications ##{appl_id}").click_link('Warteliste')
          all("#applications ##{appl_id} td").last.should have_selector('.icon-minus')

          visit group_event_application_market_index_path(group.id, event.id)

          find('#participants').text == @participants
          find('#applications').text == @applications
        end
      end

      it 'starting from application on waiting list' do
        obsolete_node_safe do
          sign_in
          visit group_event_application_market_index_path(group.id, event.id)

          @participants = find('#participants').text
          @applications = find('#applications').text

          find('#waiting_list').set(true)
          click_button('Aktualisieren')

          @participants = find('#participants').text
          @applications = find('#applications').text

          appl_id = "event_participation_#{appl_waiting.id}"
          all("#applications ##{appl_id} td").last.should have_selector('.icon-ok')

          find("#applications ##{appl_id}").click_link('Warteliste')

          all("#applications ##{appl_id} td").last.should have_selector('.icon-minus')

          find("#applications ##{appl_id}").click_link('Warteliste')
          all("#applications ##{appl_id} td").last.should have_selector('.icon-ok')

          visit group_event_application_market_index_path(group.id, event.id)

          find('#participants').text == @participants
          find('#applications').text == @applications
        end
      end
    end

    context 'participant' do
      it 'starting from application' do
        obsolete_node_safe do
          sign_in
          visit group_event_application_market_index_path(group.id, event.id)

          @participants = find('#participants').text
          @applications = find('#applications').text

          appl_id = "event_participation_#{appl_prio_1.id}"

          all("#applications ##{appl_id} td").first.find("a").click
          should_not have_selector("#applications ##{appl_id}")

          # first do find().should have_content to make capybara wait for animation, then all().last
          find('#participants').should have_content(appl_prio_1.person.to_s(:list))
          all('#participants tr').last.should have_content(appl_prio_1.person.to_s(:list))

          all("#participants ##{appl_id} td").last.find("a").click
          should_not have_selector("#participants ##{appl_id}")

          # first do find().should have_content to make capybara wait for animation, then all().last
          find('#applications').should have_content(appl_prio_1.person.to_s(:list))
          all('#applications tr').last.should have_content(appl_prio_1.person.to_s(:list))

          visit group_event_application_market_index_path(group.id, event.id)

          find('#participants').text == @participants
          find('#applications').text == @applications
        end
      end

      it 'starting from application on waiting list' do
        obsolete_node_safe do
          sign_in
          visit group_event_application_market_index_path(group.id, event.id)

          @participants = find('#participants').text
          @applications = find('#applications').text

          find('#waiting_list').set(true)
          click_button('Aktualisieren')

          @participants = find('#participants').text
          @applications = find('#applications').text

          appl_id = "event_participation_#{appl_waiting.id}"

          all("#applications ##{appl_id} td").first.find("a").click

          # first do find().should have_content to make capybara wait for animation, then all().last
          find('#participants').should have_content(appl_waiting.person.to_s(:list))
          all('#participants tr').last.should have_content(appl_waiting.person.to_s(:list))
          should_not have_selector("#applications ##{appl_id}")

          all("#participants ##{appl_id} td").last.find("a").click
          should_not have_selector("#participants ##{appl_id}")

          # first do find().should have_content to make capybara wait for animation, then all().last
          find('#applications').should have_content(appl_waiting.person.to_s(:list))
          all('#applications tr').last.should have_content(appl_waiting.person.to_s(:list))

          visit group_event_application_market_index_path(group.id, event.id)

          find('#participants').text == @participants
          find('#applications').text == @applications
        end
      end

      it 'starting from participant' do
        obsolete_node_safe do
          sign_in
          visit group_event_application_market_index_path(group.id, event.id)

          @participants = find('#participants').text
          @applications = find('#applications').text

          appl_id = "event_participation_#{appl_participant.id}"

          all("#participants ##{appl_id} td").last.find("a").click
          should_not have_selector("#participants ##{appl_id}")

          # first do find().should have_content to make capybara wait for animation, then all().last
          find('#applications').should have_content(appl_participant.person.to_s(:list))
          all('#applications tr').last.should have_content(appl_participant.person.to_s(:list))
          all("#applications ##{appl_id} td").first.find("a").click

          # first do find().should have_content to make capybara wait for animation, then all().last
          find('#participants tr').should have_content(appl_participant.person.to_s(:list))
          all('#participants tr').last.should have_content(appl_participant.person.to_s(:list))
          should_not have_selector("#applications ##{appl_id}")

          visit group_event_application_market_index_path(group.id, event.id)

          find('#participants').text == @participants
          find('#applications').text == @applications
        end
      end

    end
  end

end
