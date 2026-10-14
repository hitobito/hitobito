#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ApplicationMarketController do
  let(:event) { events(:top_course) }
  let(:group) { event.groups.first }

  let_it_be(:appl_prio_1, reload: true) do
    p = Fabricate(:event_participation,
      event: events(:top_course),
      active: false,
      application: Fabricate(:event_application, priority_1: events(:top_course)))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: p)
    p.reload
  end

  let_it_be(:appl_prio_2, reload: true) do
    p = Fabricate(:event_participation,
      active: false,
      event: Fabricate(:course, kind: events(:top_course).kind),
      application: Fabricate(:event_application, priority_2: events(:top_course)))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: p)
    p.reload
  end

  let_it_be(:appl_prio_3, reload: true) do
    p = Fabricate(:event_participation,
      active: false,
      event: Fabricate(:course, kind: events(:top_course).kind),
      application: Fabricate(:event_application, priority_3: events(:top_course)))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: p)
    p.reload
  end

  let_it_be(:appl_waiting, reload: true) do
    p = Fabricate(:event_participation,
      active: false,
      application: Fabricate(:event_application, waiting_list: true),
      event: Fabricate(:course, kind: events(:top_course).kind))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: p)
    p.reload
  end

  let_it_be(:appl_other, reload: true) do
    p = Fabricate(:event_participation,
      active: false,
      event: Fabricate(:course, kind: events(:top_course).kind),
      application: Fabricate(:event_application))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: p)
    p.reload
  end

  let_it_be(:appl_other_assigned, reload: true) do
    participation = Fabricate(:event_participation,
      event: Fabricate(:course, kind: events(:top_course).kind),
      active: true,
      application: Fabricate(:event_application, priority_2: events(:top_course)))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    participation.reload
  end

  let_it_be(:appl_participant, reload: true) do
    participation = Fabricate(:event_participation,
      event: events(:top_course),
      active: true,
      application: Fabricate(:event_application, priority_2: events(:top_course)))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    participation.reload
  end

  let_it_be(:leader, reload: true) do
    participation = Fabricate(:event_participation, event: events(:top_course))
    Fabricate(Event::Role::Leader.name.to_sym, participation: participation)
  end

  before { sign_in(people(:top_leader)) }

  describe "GET index" do
    let(:updated_at) { 1.day.ago.change(usec: 0) }
    let(:created_at) { 2.days.ago.change(usec: 0) }

    before { Event::Participation.update_all(created_at:, updated_at:) }

    context "with standard filter" do
      before { get :index, params: {group_id: group.id, event_id: event.id} }

      context "participants" do
        subject { assigns(:participants) }

        it "has 1 item" do
          expect(subject.size).to eq(1)
        end

        it "contains participant" do
          is_expected.to include(appl_participant)
        end

        it "shows the correct timestamps on the application instances" do
          expect(subject.first.model.created_at).to eq created_at
          expect(subject.first.model.updated_at).to eq updated_at
        end

        it "does not contain unassigned applications" do
          is_expected.not_to include(appl_prio_1)
        end

        it "does not contain leader" do
          is_expected.not_to include(leader)
        end
      end

      context "applications" do
        subject { assigns(:applications) }

        it "has 1 item" do
          expect(subject.size).to eq(1)
        end

        it { is_expected.to include(appl_prio_1) }
        it { is_expected.not_to include(appl_prio_2) }
        it { is_expected.not_to include(appl_prio_3) }
        it { is_expected.not_to include(appl_waiting) }

        it { is_expected.not_to include(appl_participant) }
        it { is_expected.not_to include(appl_other) }
        it { is_expected.not_to include(appl_other_assigned) }

        it "shows the correct timestamps on the application instances" do
          expect(subject.first.model.created_at).to eq created_at
          expect(subject.first.model.updated_at).to eq updated_at
        end
      end
    end

    context "with mixed prio filter" do
      before { get :index, params: {group_id: group.id, event_id: event.id, prio: %w[1 3]} }

      subject { assigns(:applications) }

      it "has 2 items" do
        expect(subject.size).to eq(2)
      end

      it { is_expected.to include(appl_prio_1) }
      it { is_expected.not_to include(appl_prio_2) }
      it { is_expected.to include(appl_prio_3) }
      it { is_expected.not_to include(appl_waiting) }

      it "shows the correct timestamps on the application instances" do
        expect(subject.map { _1.model.created_at }).to eq [created_at, created_at]
        expect(subject.map { _1.model.updated_at }).to eq [updated_at, updated_at]
      end
    end

    context "with prio and waiting list filter" do
      before { get :index, params: {group_id: group.id, event_id: event.id, prio: %w[2], waiting_list: true} }

      subject { assigns(:applications) }

      it "has 2 items" do
        expect(subject.size).to eq(2)
      end

      it { is_expected.not_to include(appl_prio_1) }
      it { is_expected.to include(appl_prio_2) }
      it { is_expected.not_to include(appl_prio_3) }
      it { is_expected.to include(appl_waiting) }

      it "shows the correct timestamps on the application instances" do
        expect(subject.map { _1.model.created_at }).to eq [created_at, created_at]
        expect(subject.map { _1.model.updated_at }).to eq [updated_at, updated_at]
      end
    end

    context "with waiting list filter" do
      before { get :index, params: {group_id: group.id, event_id: event.id, waiting_list: true} }

      subject { assigns(:applications) }

      it "has 1 item" do
        expect(subject.size).to eq(1)
      end

      it { is_expected.not_to include(appl_prio_1) }
      it { is_expected.not_to include(appl_prio_2) }
      it { is_expected.not_to include(appl_prio_3) }
      it { is_expected.to include(appl_waiting) }

      it "shows the correct timestamps on the application instances" do
        expect(subject.map { _1.model.created_at }).to eq [created_at]
        expect(subject.map { _1.model.updated_at }).to eq [updated_at]
      end
    end

    context "for regular event" do
      let(:event) { events(:top_event) }


      it "is not possible" do
        expect do
          get :index, params: {group_id: group.id, event_id: event.id}
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe "PUT participant" do
    it "creates role" do
      put :add_participant, params: {group_id: group.id, event_id: event.id, id: appl_prio_1.id}, format: :js

      expect(appl_prio_1.reload.roles.collect(&:type)).to eq([event.participant_types.first.sti_name])
      expect(appl_prio_1).to be_active
    end

    it "shows error on existing participant role" do
      other = Fabricate(:course, groups: [groups(:top_layer)])
      create_participant_role(other)

      put :add_participant, params: {group_id: group.id, event_id: other.id, id: appl_prio_1.id}, format: :js

      is_expected.to render_template("participation_exists_error")
    end

    it "sends email when send_email query param is true" do
      expect do
        put :add_participant, params: {group_id: group.id, event_id: event.id, id: appl_prio_1.id, send_email: true},
          format: :js
      end.to change { Delayed::Job.where("handler LIKE '%Event::ParticipationConfirmationJob%'").count }.by(1)
    end

    it "does not send email when send_email query param is false" do
      expect do
        put :add_participant, params: {group_id: group.id, event_id: event.id, id: appl_prio_1.id, send_email: false},
          format: :js
      end.not_to change { Delayed::Job.where("handler LIKE '%Event::ParticipationConfirmationJob%'").count }
    end

    def create_participant_role(other)
      participation = Fabricate(:event_participation,
        event: other,
        participant: appl_prio_1.person,
        application: Fabricate(:event_application),
        active: true)
      role = other.participant_types.first.new
      role.participation = participation
      role.save!
    end
  end

  describe "DELETE participant" do
    it "deactivates participation" do
      delete :remove_participant, params: {group_id: group.id, event_id: event.id, id: appl_participant.id}, format: :js
      expect(appl_participant.reload).not_to be_active
    end

    it "sends email when send_email query param is true" do
      expect do
        delete :remove_participant,
          params: {group_id: group.id, event_id: event.id, id: appl_participant.id, send_email: true}, format: :js
      end.to change { Delayed::Job.where("handler LIKE '%Event::ParticipationConfirmationJob%'").count }.by(1)
    end

    it "does not send email when send_email query param is false" do
      expect do
        delete :remove_participant,
          params: {group_id: group.id, event_id: event.id, id: appl_participant.id, send_email: false}, format: :js
      end.not_to change { Delayed::Job.where("handler LIKE '%Event::ParticipationConfirmationJob%'").count }
    end
  end

  describe "PUT waiting_list" do
    before do
      put :put_on_waiting_list,
        params: {
          group_id: group.id,
          event_id: event.id,
          id: appl_prio_1.id,
          event_application: {waiting_list_comment: "foo bar"}
        },
        format: :js
    end

    it "sets waiting list flag" do
      expect(appl_prio_1.reload.application).to be_waiting_list
      expect(appl_prio_1.application.waiting_list_comment).to eq("foo bar")
    end
  end

  describe "DELETE waiting_list" do
    before {
      delete :remove_from_waiting_list, params: {group_id: group.id, event_id: event.id, id: appl_waiting.id},
        format: :js
    }

    it "sets waiting list flag" do
      expect(appl_waiting.reload.application).not_to be_waiting_list
    end
  end
end
