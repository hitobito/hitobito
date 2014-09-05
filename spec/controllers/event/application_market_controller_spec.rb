# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ApplicationMarketController do

  let(:event) { events(:top_course) }
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

  before { sign_in(people(:top_leader)) }

  describe 'GET index' do

    context 'with standard filter' do
      before { get :index, group_id: group.id, event_id: event.id }

      context 'participants' do
        subject { assigns(:participants) }

        it { should have(1).items }

        it 'contains participant' do
          should include(appl_participant)
        end

        it 'does not contain unassigned applications' do
          should_not include(appl_prio_1)
        end

        it 'does not contain leader' do
          should_not include(leader)
        end
      end

      context 'applications' do
        subject { assigns(:applications) }

        it { should have(1).items }

        it { should include(appl_prio_1) }
        it { should_not include(appl_prio_2) }
        it { should_not include(appl_prio_3) }
        it { should_not include(appl_waiting) }

        it { should_not include(appl_participant) }
        it { should_not include(appl_other) }
        it { should_not include(appl_other_assigned) }
      end
    end

    context 'with mixed prio filter' do
      before { get :index, group_id: group.id, event_id: event.id, prio: %w(1 3) }

      subject { assigns(:applications) }

      it { should have(2).items }

      it { should include(appl_prio_1) }
      it { should_not include(appl_prio_2) }
      it { should include(appl_prio_3) }
      it { should_not include(appl_waiting) }
    end

    context 'with prio and waiting list filter' do
      before { get :index, group_id: group.id, event_id: event.id, prio: %w(2), waiting_list: true }

      subject { assigns(:applications) }

      it { should have(2).items }

      it { should_not include(appl_prio_1) }
      it { should include(appl_prio_2) }
      it { should_not include(appl_prio_3) }
      it { should include(appl_waiting) }
    end

    context 'with waiting list filter' do
      before { get :index, group_id: group.id, event_id: event.id, waiting_list: true }

      subject { assigns(:applications) }

      it { should have(1).items }

      it { should_not include(appl_prio_1) }
      it { should_not include(appl_prio_2) }
      it { should_not include(appl_prio_3) }
      it { should include(appl_waiting) }
    end
  end


  describe 'PUT participant' do

    it 'creates role' do
      put :add_participant, group_id: group.id, event_id: event.id, id: appl_prio_1.id, format: :js

      appl_prio_1.reload.roles.collect(&:type).should == [event.participant_type.sti_name]
    end

    it 'shows error on existing participant role' do
      other = Fabricate(:course, groups: [groups(:top_layer)])
      create_participant_role(other)

      put :add_participant, group_id: group.id, event_id: other.id, id: appl_prio_1.id, format: :js

      should render_template('participation_exists_error')
    end

    def create_participant_role(other)
      participation = Fabricate(:event_participation, event: other, person: appl_prio_1.person, application: Fabricate(:event_application))
      role = other.participant_type.new
      role.participation = participation
      role.save!
    end
  end

  describe 'DELETE participant' do
    before { delete :remove_participant, group_id: group.id, event_id: event.id, id: appl_participant.id, format: :js }

    it 'removes role' do
      appl_participant.reload.roles.should_not be_exists
    end
  end

  describe 'PUT waiting_list' do
    before { put :put_on_waiting_list, group_id: group.id, event_id: event.id, id: appl_prio_1.id, format: :js }

    it 'sets waiting list flag' do
      appl_prio_1.reload.application.should be_waiting_list
    end
  end

  describe 'DELETE waiting_list' do
    before { delete :remove_from_waiting_list, group_id: group.id, event_id: event.id, id: appl_waiting.id, format: :js }

    it 'sets waiting list flag' do
      appl_waiting.reload.application.should_not be_waiting_list
    end
  end

end
