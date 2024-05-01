# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationsController do

  let(:group) { groups(:top_layer) }

  let!(:other_course) do
    other = Fabricate(:course, groups: [group], kind: course.kind)
    other.dates << Fabricate(:event_date, event: other, start_at: course.dates.first.start_at)
    other
  end

  let(:course) do
    course = Fabricate(:course, groups: [group], priorization: true)
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course.dates << Fabricate(:event_date, event: course)
    course
  end

  let(:participation) do
    p = Fabricate(:event_participation,
                  event: course,
                  application: Fabricate(:event_application,
                                         priority_1: course,
                                         priority_2: Fabricate(:course, kind: course.kind)))
    p.answers.detect { |a| a.question_id == course.questions[0].id }.update!(answer: 'juhu')
    p.answers.detect { |a| a.question_id == course.questions[1].id }.update!(answer: 'blabla')
    p
  end

  let(:user) { people(:top_leader) }

  before do
    user.qualifications << Fabricate(:qualification, qualification_kind: qualification_kinds(:gl),
                                                     start_at: course.dates.first.start_at)
    sign_in(user)
  end


  context 'GET index' do
    before do
      @leader, @participant = *create(Event::Role::Leader, course.participant_types.first)

      update_person(@participant, first_name: 'Al', last_name: 'Barns', nickname: 'al',
                                  town: 'Eye', address: 'Spring Road', zip_code: '3000',
                                  birthday: '21.10.1978')
      update_person(@leader, first_name: 'Joe', last_name: 'Smith', nickname: 'js',
                             town: 'Stoke', address: 'Howard Street', zip_code: '8000',
                             birthday: '1.3.1992')
    end

    it 'lists participant and leader group by default' do
      get :index, params: { group_id: group.id, event_id: course.id }
      expect(assigns(:participations)).to eq [@participant, @leader]
      expect(assigns(:person_add_requests)).to eq([])
    end

    it 'lists particpant and leader group by default order by role if specific in settings' do
      allow(Settings.people).to receive_messages(default_sort: 'role')
      get :index, params: { group_id: group.id, event_id: course.id }
      expect(assigns(:participations)).to eq [@leader, @participant]
    end

    it 'lists only leader_group' do
      get :index, params: { group_id: group.id, event_id: course.id, filter: :teamers }
      expect(assigns(:participations)).to eq [@leader]
    end

    it 'lists only participant_group' do
      get :index, params: { group_id: group.id, event_id: course.id, filter: :participants }
      expect(assigns(:participations)).to eq [@participant]
    end

    it 'generates pdf labels' do
      get :index, format: :pdf, params: {
        group_id: group, event_id: course.id, label_format_id: label_formats(:standard).id
      }

      expect(@response.media_type).to eq('application/pdf')
      expect(people(:top_leader).reload.last_label_format).to eq(label_formats(:standard))
    end

    it 'exports csv files' do
      expect do
        get :index, params: { group_id: group, event_id: course.id }, format: :csv
        expect(flash[:notice]).to match(
          /Export wird im Hintergrund gestartet und nach Fertigstellung heruntergeladen./
        )
      end.to change(Delayed::Job, :count).by(1)
    end

    it 'exports xlsx files' do
      expect do
        get :index, params: { group_id: group, event_id: course.id }, format: :xlsx
        expect(flash[:notice]).to match(
          /Export wird im Hintergrund gestartet und nach Fertigstellung heruntergeladen./
        )
      end.to change(Delayed::Job, :count).by(1)
    end

    it 'sets cookie on export' do
      get :index, params: { group_id: group, event_id: course.id }, format: :csv

      cookie = JSON.parse(cookies[Cookies::AsyncDownload::NAME])

      expect(cookie[0]['name']).to match(
        /^(event_participation_export)+\S*(#{people(:top_leader).id})+$/
      )
      expect(cookie[0]['type']).to match(/^csv$/)
    end

    it 'renders email addresses with additional ones' do
      e1 = Fabricate(:additional_email, contactable: @participant.person, mailings: true)
      Fabricate(:additional_email, contactable: @leader.person, mailings: false)
      get :index, params: { group_id: group, event_id: course.id }, format: :email
      expect(@response.body.split(',')).to match_array([
                                                         @participant.person.email,
                                                         @leader.person.email,
                                                         e1.email
                                                       ])
    end

    it 'loads pending person add requests' do
      r1 = Person::AddRequest::Event.create!(
        person: Fabricate(:person),
        requester: Fabricate(:person),
        body: course,
        role_type: course.class.role_types.first.sti_name
      )

      get :index, params: { group_id: group.id, event_id: course.id }
      expect(assigns(:participations)).to eq [@participant, @leader]
      expect(assigns(:person_add_requests)).to eq([r1])
    end

    it 'renders json' do
      get :index, params: { group_id: group.id, event_id: course.id }, format: :json
      json = JSON.parse(response.body).deep_symbolize_keys
      expect(json[:current_page]).to eq 1
      expect(json[:total_pages]).to eq 1
      expect(json[:next_page_link]).to be_nil
      expect(json[:prev_page_link]).to be_nil
      expect(json[:event_participations]).to have(2).items
    end

    it 'renders json for service token user' do
      allow(controller).to receive_messages(current_user: nil)

      get :index, params: { group_id: group.id, event_id: course.id, token: 'PermittedToken' },
                  format: :json
      json = JSON.parse(response.body).deep_symbolize_keys
      expect(json[:current_page]).to eq 1
    end

    it 'redirects for service token csv request' do
      allow(controller).to receive_messages(current_user: nil)

      get :index, params: { group_id: group.id, event_id: course.id, token: 'PermittedToken' },
                  format: :csv
      expect(response).to redirect_to group_event_participations_path(group, course, returning: true)
    end

    context 'sorting' do
      %w(first_name last_name nickname zip_code town birthday).each do |attr|
        it "sorts based on #{attr}" do
          get :index, params: { group_id: group, event_id: course.id, sort: attr, sort_dir: :asc }
          expect(assigns(:participations)).to eq([@participant, @leader])
        end
      end

      it 'sorts based on role' do
        get :index, params: { group_id: group, event_id: course.id, sort: :roles, sort_dir: :asc }
        expect(assigns(:participations)).to eq([@leader, @participant])
      end
    end

    it 'participant can index other participants' do
      sign_in(@participant.person)
      get :index, params: { group_id: groups(:bottom_layer_one), event_id: course.id }
    end

    def create(*roles)
      roles.map do |role_class|
        role = Fabricate(:event_role, type: role_class.sti_name)
        Fabricate(:event_participation, event: course, roles: [role], active: true)
      end
    end

    def update_person(participation, attrs)
      participation.person.update!(attrs)
    end
  end


  context 'GET show' do

    it 'renders json' do
      get :show, params: { group_id: group.id, event_id: course.id, id: participation.id },
                 format: :json
      json = JSON.parse(response.body).deep_symbolize_keys
      expect(json[:event_participations]).to have(1).items
    end

    context 'for same event' do
      before do
        get :show, params: { group_id: group.id, event_id: course.id, id: participation.id }
      end

      it 'has two answers' do
        expect(assigns(:answers).size).to eq(2)
      end

      it 'has application' do
        expect(assigns(:application)).to be_present
      end
    end

    context 'for other event of same group' do
      before do
        get :show, params: { group_id: group.id, event_id: other_course.id, id: participation.id }
      end

      it 'has participation' do
        expect(assigns(:participation)).to eq(participation)
      end
    end

    context 'for other event of other group' do

      let(:group) { groups(:bottom_layer_one) }
      let(:user) do
        Fabricate(Group::BottomLayer::Leader.sti_name.to_sym,
                  group: groups(:bottom_layer_one)).person
      end
      let(:other_course) do
        other = Fabricate(:course, groups: [groups(:bottom_layer_two)], kind: course.kind)
        other.dates << Fabricate(:event_date, event: other, start_at: course.dates.first.start_at)
        other
      end

      context 'on prio 2' do
        let(:participation) do
          p = Fabricate(:event_participation,
                        event: other_course,
                        application: Fabricate(:event_application,
                                               priority_2: course))
          p.answers.create!(question_id: course.questions[0].id, answer: 'juhu')
          p.answers.create!(question_id: course.questions[1].id, answer: 'blabla')
          p
        end

        before do
          get :show, params: { group_id: group.id, event_id: course.id, id: participation.id }
        end

        it 'has participation' do
          expect(response.status).to eq(200)
          expect(assigns(:participation)).to eq(participation)
        end
      end

      context 'on waiting list' do
        let(:participation) do
          p = Fabricate(:event_participation,
                        event: other_course,
                        application: Fabricate(:event_application,
                                               waiting_list: true))
          p
        end

        before do
          get :show, params: { group_id: group.id, event_id: course.id, id: participation.id }
        end

        it 'has participation' do
          expect(response.status).to eq(200)
          expect(assigns(:participation)).to eq(participation)
        end
      end

    end

    context 'simple event' do
      let(:simple_event) do
        simple_event = Fabricate(:event, groups: [group])
        simple_event.dates << Fabricate(:event_date, event: simple_event)
        simple_event
      end
      let(:participation) { Fabricate(:event_participation, event: simple_event) }

      it 'renders without errors (regression for load_precondition_warnings error on nil kind)' do
        get :show, params: { group_id: group.id, event_id: simple_event.id, id: participation.id }
      end
    end

  end

  context 'GET print' do
    render_views

    it 'renders participation as pdf' do
      get :print, params: { group_id: group.id, event_id: course.id, id: participation.id },
                  format: :pdf
      expect(response).to be_ok
    end
  end

  context 'GET new' do
    context 'for course with priorization' do
      before { get :new, params: { group_id: group.id, event_id: event.id } }

      let(:event) { course }

      it 'builds participation with answers' do
        participation = assigns(:participation)
        expect(participation.application).to be_present
        expect(participation.application.priority_1).to eq(course)
        expect(participation.answers.size).to eq(2)
        expect(participation.person).to eq(user)
        expect(assigns(:priority_2s).collect(&:id)).to match_array([events(:top_course).id,
                                                                    other_course.id])
        expect(assigns(:alternatives).collect(&:id)).to match_array([events(:top_course).id,
                                                                     course.id, other_course.id])
      end
    end

    context 'for event without application' do
      before { get :new, params: { group_id: group.id, event_id: event.id } }

      let(:event) do
        event = Fabricate(:event, groups: [group])
        event.questions << Fabricate(:event_question, event: event)
        event.questions << Fabricate(:event_question, event: event)
        event.dates << Fabricate(:event_date, event: event)
        event
      end

      it 'builds participation with answers' do
        participation = assigns(:participation)
        expect(participation.application).to be_blank
        expect(participation.answers.size).to eq(2)
        expect(participation.person).to eq(user)
        expect(assigns(:priority_2s)).to be_nil
      end
    end

    context 'unauthenticated' do
      before { sign_out(user) }

      context 'event that does not support applications' do
        let(:event) { events(:top_event) }

        it 'does not throw any exception (regression test for #16403)' do
          get :new, params: { group_id: group.id, event_id: event.id }
        end
      end

      context 'event that supports applications' do
        let(:event) { course }

        it 'is fine when event supports applications (regression test for #16403)' do
          get :new, params: { group_id: group.id, event_id: event.id }
        end
      end
    end

  end

  context 'POST create' do
    let(:pending_dj_handlers) { Delayed::Job.all.pluck(:handler) }

    context 'for current user' do
      let(:user) { people(:bottom_member) }
      let(:app1)    { Fabricate(:person, email: 'approver1@example.com') }
      let(:app2)    { Fabricate(:person, email: 'approver2@example.com') }

      before do
        # create two approvers for user
        Fabricate(Group::BottomLayer::Leader.name.to_sym, person: app1,
                                                          group: groups(:bottom_layer_one))
        Fabricate(Group::BottomLayer::Leader.name.to_sym, person: app2,
                                                          group: groups(:bottom_layer_one))

        user.qualifications << Fabricate(:qualification,
                                         qualification_kind: qualification_kinds(:sl))
      end

      it 'creates pending confirmation and notification job for course' do
        expect do
          post :create, params: { group_id: group.id, event_id: course.id, event_participation: {} }
          expect(assigns(:participation)).to be_valid
        end.to change { Delayed::Job.count }.by(2)

        expect(pending_dj_handlers).to be_one{ |h| h =~ /Event::ParticipationNotificationJob/}
        expect(pending_dj_handlers).to be_one{ |h| h =~ /Event::ParticipationConfirmationJob/}

        expect(flash[:notice]).to be_nil
        expect(flash[:warning]).
          to include "Es wurde eine Voranmeldung für Teilnahme von <i>#{user}</i> in <i>Eventus</i> erstellt. Die Teilnahme ist noch nicht definitiv und muss von der Anlassverwaltung bestätigt werden."
      end

      it 'creates pending confirmation with waiting list info' do
        course.update!(waiting_list: true, maximum_participants: 1, participant_count: 1)

        expect do
          post :create, params: { group_id: group.id, event_id: course.id, event_participation: {} }
          expect(assigns(:participation)).to be_valid
        end.to change { Delayed::Job.count }.by(2)

        expect(pending_dj_handlers).to be_one{ |h| h =~ /Event::ParticipationNotificationJob/}
        expect(pending_dj_handlers).to be_one{ |h| h =~ /Event::ParticipationConfirmationJob/}

        expect(flash[:notice]).to be_nil
        expect(flash[:warning]).
          to include "Es wurde eine Voranmeldung für Teilnahme von <i>#{user}</i> in <i>Eventus</i> erstellt. Die Teilnahme ist noch nicht definitiv und muss von der Anlassverwaltung bestätigt werden."
        expect(flash[:alert]).to include 'Es sind derzeit alle Plätze belegt, die Anmeldung ist auf der Warteliste.'
      end

      it 'without waiting list directly assigns place and creates confirmation' do
        course.update!(waiting_list: false, maximum_participants: 2, participant_count: 1, automatic_assignment: true)

        expect do
          post :create, params: { group_id: group.id, event_id: course.id, event_participation: {} }
          expect(assigns(:participation)).to be_valid
        end.to change { Delayed::Job.count } #.by(2)

        expect(pending_dj_handlers).to be_one{ |h| h =~ /Event::ParticipationNotificationJob/}
        expect(pending_dj_handlers).to be_one{ |h| h =~ /Event::ParticipationConfirmationJob/}

        expect(flash[:notice]).
          to include "Teilnahme von <i>#{user}</i> in <i>Eventus</i> wurde erfolgreich erstellt. Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an."
        expect(flash[:warning]).to be_nil
      end

      it 'creates non-active participant role for course events' do
        groups(:top_layer).update_column(:require_person_add_requests, true)
        post :create, params: { group_id: group.id, event_id: course.id, event_participation: {} }

        participation = assigns(:participation)
        expect(participation).to be_valid
        expect(participation).not_to be_active
        expect(participation.roles.size).to eq(1)
        role = participation.roles.first
        expect(role).to be_kind_of(Event::Course::Role::Participant)
        expect(role.participation).to eq participation.model

        expect(course.reload.applicant_count).to eq 1
        expect(course.teamer_count).to eq 0
        expect(course.participant_count).to eq 0

        expect(participation.application).to be_present

        expect(flash[:notice]).to be_nil
        expect(flash[:warning]).
          to include "Es wurde eine Voranmeldung für Teilnahme von <i>#{user}</i> in <i>Eventus</i> erstellt. Die Teilnahme ist noch nicht definitiv und muss von der Anlassverwaltung bestätigt werden."
      end

      it 'creates specific non-active participant role for course events' do
        class TestParticipant < Event::Course::Role::Participant; end
        Event::Course.role_types << TestParticipant
        post :create, params: {
          group_id: group.id,
          event_id: course.id,
          event_participation: {},
          event_role: { type: 'TestParticipant' }
        }
        Event::Course.role_types -= [TestParticipant]
        participation = assigns(:participation)
        expect(participation).to be_valid
        expect(participation).not_to be_active
        expect(participation.roles.size).to eq(1)
        role = participation.roles.first
        expect(role).to be_kind_of(TestParticipant)

        expect(flash[:notice]).to be_nil
        expect(flash[:warning]).
          to include "Es wurde eine Voranmeldung für Teilnahme von <i>#{user}</i> in <i>Eventus</i> erstellt. Die Teilnahme ist noch nicht definitiv und muss von der Anlassverwaltung bestätigt werden."
      end

      it 'creates new participation with application' do
        post :create, params: { group_id: group.id, event_id: course.id,
                                event_participation: {
                                  application_attributes: { priority_2_id: other_course.id }
                                } }

        participation = assigns(:participation)
        application = participation.application
        expect(participation).to be_valid
        expect(participation).not_to be_active
        expect(participation.roles.size).to eq(1)
        role = participation.roles.first
        expect(role).to be_kind_of(Event::Course::Role::Participant)
        expect(role.participation).to eq participation.model

        expect(course.reload.applicant_count).to eq 1
        expect(course.teamer_count).to eq 0
        expect(course.participant_count).to eq 0

        expect(application).to be_present
        expect(application.priority_2_id).to eq other_course.id

        expect(flash[:notice]).to be_nil
        expect(flash[:warning]).
          to include "Es wurde eine Voranmeldung für Teilnahme von <i>#{user}</i> in <i>Eventus</i> erstellt. Die Teilnahme ist noch nicht definitiv und muss von der Anlassverwaltung bestätigt werden."
      end

      it 'creates new participation with all answers' do
        post :create,
          params: {
            group_id: group.id,
            event_id: course.id,
            event_participation: {
              answers: {
                1 => { question_id: course.questions.first.id, answer: 'Bla' }
              }
            }
          }

        participation = assigns(:participation)
        expect(participation.answers.size).to eq(2)
      end

      it 'fails if required answers are missing' do
        expect_any_instance_of(described_class).not_to receive(:set_success_notice)
        course.questions.first.update!(required: true)

        post :create,
             params: {
               group_id: group.id,
               event_id: course.id,
               event_participation: {
                 answers: {
                   1 => { question_id: course.questions.first.id, answer: '' }
                 }
               }
             }

        expect(response).to render_template('new')
        expect(flash[:notice]).to be_nil
        expect(flash[:warning]).to be_nil
      end

      it 'fails for invalid event role' do
        expect do
          post :create, params: {
            group_id: group.id,
            event_id: course.id,
            event_participation: {},
            event_role: { type: 'DummyParticipant' }
          }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'without event kinds' do
        before do
          course.update_column(:kind_id, nil)
        end

        it 'does not check preconditions' do
          expect do
            post :create, params: { group_id: group.id, event_id: course.id,
                                    event_participation: {} }
          end.to change { Event::Participation.count }.by(1)
        end

      end

      it 'stores additional information' do
        post :create, params: { group_id: group.id, event_id: course.id,
                                event_participation: { additional_information: 'Vegetarier' } }

        expect(assigns(:participation)).to be_valid
        expect(assigns(:participation).additional_information).to eq('Vegetarier')
      end

      it 'can handle wide unicode characters (esp. emoji)', :mysql do
        post :create, params: { group_id: group.id, event_id: course.id,
                                event_participation: { additional_information: 'Vegetarier😝' } }

        expect(assigns(:participation)).to be_valid
        expect(assigns(:participation).additional_information).to eq('Vegetarier😝')
      end
    end

    context 'other user' do
      let(:user) { people(:top_leader) }
      let(:bottom_member) { people(:bottom_member) }
      let(:participation) { assigns(:participation) }

      it 'top leader can create participation for bottom member' do
        post :create, params: { group_id: group.id, event_id: course.id,
                                event_participation: { person_id: bottom_member.id } }
        expect(participation).to be_present
        expect(participation).to be_valid
        expect(participation).to be_persisted
        expect(participation).to be_active
        expect(participation.roles.pluck(:type)).to eq([Event::Course::Role::Participant.sti_name])
        is_expected.to redirect_to group_event_participation_path(group, course, participation)

        expect(flash[:notice]).
          to include 'Teilnahme von <i>Bottom Member</i> in <i>Eventus</i> wurde erfolgreich erstellt.'
      end

      it 'creates person add request if required' do
        bottom_member.event_participations.destroy_all
        course = Fabricate(:course, groups: [groups(:bottom_layer_two)])
        user = Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person
        sign_in(user)
        groups(:bottom_layer_one).update_column(:require_person_add_requests, true)

        post :create, params: { group_id: group.id, event_id: course.id,
                                event_participation: { person_id: bottom_member.id } }

        is_expected.to redirect_to(group_event_participations_path(group, course))
        expect(flash[:alert]).to match(/versendet/)

        expect(bottom_member.reload.add_requests.count).to eq(1)
        expect(bottom_member.event_participations.count).to eq(0)
      end

      it 'bottom member can not create participation for top leader' do
        sign_in(bottom_member)
        expect do
          post :create, params: { group_id: group.id, event_id: course.id,
                                  event_participation: { person_id: user.id } }
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end


  context 'DELETE destroy' do

    it 'redirects to application market' do
      delete :destroy, params: { group_id: group.id, event_id: course.id, id: participation.id }

      is_expected.to redirect_to group_event_application_market_index_path(group, course)
      expect(flash[:notice]).to match(/Anmeldung/)
      expect(Delayed::Job.where('handler LIKE ?', '%CancelApplicationJob%')).not_to exist
    end

    it 'redirects to event show if own participation' do
      participation.update_column(:person_id, user.id)
      delete :destroy, params: { group_id: group.id, event_id: course.id, id: participation.id }

      is_expected.to redirect_to group_event_path(group, course)
      expect(Delayed::Job.where('handler LIKE ?', '%CancelApplicationJob%')).to exist
    end

  end

  context 'preconditions' do
    before { user.qualifications.first.destroy }

    context 'GET show' do

      context 'for participant' do
        before do
          Fabricate(:event_role, type: Event::Course::Role::Participant.sti_name,
                    participation: participation)
        end
        before do
          get :show, params: { group_id: group.id, event_id: course.id, id: participation.id }
        end
        let(:warnings) { assigns(:precondition_warnings) }

        it 'assigns precondition_warnings' do
          expect(warnings[0]).to match(/Vorbedingungen.*nicht erfüllt/)
          expect(warnings[1]).to match(/Folgende Qualifikationen fehlen oder sind abgelaufen: Group Lead/)
        end
      end

      context 'for leader' do
        before do
          Fabricate(:event_role, type: Event::Role::Leader.sti_name,
                    participation: participation)
        end
        before do
          get :show, params: { group_id: group.id, event_id: course.id, id: participation.id }
        end
        let(:warnings) { assigns(:precondition_warnings) }

        it 'does not assign precondition_warnings' do
          expect(warnings).to be_nil
        end
      end
    end

    context 'GET new' do
      before { get :new, params: { group_id: group.id, event_id: course.id } }

      it 'sets answers instance variable' do
        expect(assigns(:answers)).to have(2).item
      end

      it 'allows the user to apply' do
        is_expected.to_not redirect_to group_event_path(group, course)
      end

      it 'displays flash message' do
        expect(flash[:alert].last).to match(/Folgende Qualifikationen fehlen oder sind abgelaufen: Group Lead/)
      end
    end

    context 'POST create' do
      before { post :create, params: { group_id: group.id, event_id: course.id } }
      let(:participation) { assigns(:participation) }

      it 'allows the user to apply' do
        expect(participation).to be_present
        expect(participation.persisted?).to be_truthy
      end

      it 'does not display a flash message' do
        expect(flash[:alert]).to be_blank
      end
    end
  end

  context 'required answers' do
    let(:event) { events(:top_event) }

    def make_request(person, answer)
      question = event.questions.create!(question: 'dummy', required: true)
      sign_in(person)

      post :create, params: { group_id: event.groups.first.id, event_id: event.id,
                              event_participation: { answers_attributes: {
                                '0' => { 'question_id' => question.id, 'answer' => answer }
                              } } }
      assigns(:participation)
    end

    it 'top_leader can create without supplying required answer' do
      expect(make_request(people(:top_leader), '')).to be_valid
    end

    it 'bottom_member cannot create without supplying required answer' do
      expect(make_request(people(:bottom_member), '')).not_to be_valid
    end

    it 'bottom_member can create when supplying required answer' do
      expect(make_request(people(:bottom_member), 'dummy')).to be_valid
    end
  end

  context 'mandatory single checkbox answer' do
    let(:event) { events(:top_event) }
    let(:person) { people(:bottom_member) }

    let!(:question) do
      event.questions.create!(
        question: 'Terms and Conditions? Do you speak it?',
        choices: 'yep',
        required: true
      )
    end

    before do
      sign_in(person)
    end

    it 'bottom_member cannot create without supplying required answer' do
      post :create, params: { group_id: event.groups.first.id, event_id: event.id,
                              event_participation: {} } # <- look ma, no answer!

      expect(assigns(:participation)).not_to be_valid
    end

    it 'bottom_member can create when supplying required answer' do
      post :create, params: { group_id: event.groups.first.id, event_id: event.id,
                              event_participation: { answers_attributes: {
                                '0' => { 'question_id' => question.id, 'answer' => 'yep' }
                              } } }

      expect(assigns(:participation)).to be_valid
    end
  end


  context 'multiple choice answers' do
    let(:event) { events(:top_event) }
    let(:question) { event_questions(:top_ov) }

    before do
      question.update_attribute(:multiple_choices, true)
      event.questions << question
    end

    context 'POST #create' do
      let(:answers_attributes) { { '0' => { 'question_id' => question.id, 'answer' => %w(1 2) } } }

      it 'handles multiple choice answers' do
        post :create, params: {
          group_id: event.groups.first.id,
          event_id: event.id,
          event_participation: { answers_attributes: answers_attributes }
        }
        expect(assigns(:participation).answers.first.answer).to eq 'GA, Halbtax'
      end
    end

    context 'PUT #update' do
      let!(:participation) { Fabricate(:event_participation, event: event, person: user) }
      let(:answer) { participation.answers.where(question_id: question.id).first }
      let(:answers_attributes) do
        { '0' => { 'question_id' => question.id, 'answer' => ['0'], id: answer.id } }
      end

      before do
        answer.answer = 'GA, Halbtax'
        answer.save!
      end

      it 'handles resetting of multiple choice answers' do
        expect(participation.reload.answers.first.answer).to eq 'GA, Halbtax'
        put :update, params: {
          group_id: event.groups.first.id,
          event_id: event.id,
          id: participation.id,
          event_participation: { answers_attributes: answers_attributes }
        }
        expect(participation.reload.answers.first.answer).to be_nil
      end
    end
  end

  context 'table_displays' do
    render_views
    let(:dom)           { Capybara::Node::Simple.new(response.body) }
    let(:top_leader)    { people(:top_leader) }
    let(:course)        { events(:top_course) }
    let(:participation) { event_participations(:top) }
    let(:question)      { event_questions(:top_ov) }

    let!(:registered_columns) { TableDisplay.table_display_columns.clone }
    let!(:registered_multi_columns) { TableDisplay.multi_columns.clone }

    before do
      TableDisplay.table_display_columns = {}
      TableDisplay.multi_columns = {}
      sign_in(top_leader)
    end

    after do
      TableDisplay.table_display_columns = registered_columns
      TableDisplay.multi_columns = registered_multi_columns
    end

    it 'GET#index lists extra person column' do
      TableDisplay.register_column(Event::Participation, TableDisplays::PublicColumn, 'person.gender')
      table_display = top_leader.table_display_for(Event::Participation)
      table_display.selected = %w(person.gender)
      table_display.save!

      get :index, params: { group_id: group.id, event_id: course.id }
      expect(dom).to have_checked_field 'Geschlecht'
      expect(dom.find('table tbody tr')).to have_content 'unbekannt'
    end

    it 'GET#index lists extra event application question' do
      TableDisplay.register_multi_column(Event::Participation, TableDisplays::Event::Participations::QuestionColumn)
      table_display = top_leader.table_display_for(Event::Participation)
      table_display.selected = %W[event_question_#{question.id}]
      table_display.save!
      participation.answers.create!(question: question, answer: 'GA')

      get :index, params: { group_id: group.id, event_id: course.id }
      expect(dom).to have_checked_field 'GA oder Halbtax?'
      expect(dom.find('table tbody tr')).to have_content 'GA'
    end

    it 'GET#index handles missing event application answer gracefully' do
      TableDisplay.register_multi_column(Event::Participation, TableDisplays::Event::Participations::QuestionColumn)
      table_display = top_leader.table_display_for(Event::Participation)
      table_display.selected = %W[event_question_#{question.id}]
      table_display.save!

      get :index, params: { group_id: group.id, event_id: course.id }
      expect(dom).to have_checked_field 'GA oder Halbtax?'
      # successfully renders, even though no answer is present in the database
    end

    it 'GET#index sorts by extra event application question' do
      TableDisplay.register_multi_column(Event::Participation, TableDisplays::Event::Participations::QuestionColumn)
      table_display = top_leader.table_display_for(Event::Participation)
      table_display.selected = %W[event_question_#{question.id}]
      table_display.save!
      role = Fabricate(:event_role, type: participation.roles.first.type)
      other = Fabricate(:event_participation, event: course, roles: [role], active: true)

      participation.answers.create!(question: question, answer: 'GA')
      other.answers.find { |a| a.question == question }.update(answer: 'Halbtax')

      get :index, params: { group_id: group.id, event_id: course.id,
                            sort: "event_question_#{question.id}", sort_dir: :desc }
      expect(assigns(:participations).first).to eq other
    end

    it 'GET#index exports to csv using TableDisplay' do
      get :index, params: { group_id: group.id, event_id: course.id, selection: true }, format: :csv
      expect(flash[:notice]).to match(
        /Export wird im Hintergrund gestartet und nach Fertigstellung heruntergeladen./
      )
      expect(Delayed::Job.last.payload_object.send(:exporter))
        .to eq Export::Tabular::Event::Participations::TableDisplays
    end
  end

  context 'table_displays as configured in the core' do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }
    let(:course) { Fabricate(:course, groups: [groups(:bottom_layer_two)], participations_visible: true) }
    let(:group) { Fabricate(Group::TopGroup.name, parent: groups(:top_group)) }
    let(:user) { Fabricate(:person) }
    let!(:role) { Fabricate(Group::BottomLayer::Leader.name, person: user, group: groups(:bottom_layer_one)) }
    let!(:participation) { Fabricate(:event_participation, person: user, event: course, active: true) }
    let(:other_person) { Fabricate(:person, birthday: Date.new(2003, 03, 03), company_name: 'Puzzle ITC Test') }
    let!(:other_role) { Fabricate(Group::TopGroup::Member.name, person: other_person, group: group) }
    let!(:other_participation) { Fabricate(:event_participation, person: other_person, event: course, active: true) }
    let!(:other_event_role) { Fabricate(Event::Course::Role::Participant.name, participation: other_participation) }

    before { sign_in(user.reload) }

    context 'with show_details permission' do
      let!(:role2) { Fabricate(Group::TopLayer::TopAdmin.name, person: user, group: groups(:top_layer)) }
      let!(:event_role) { Fabricate(Event::Course::Role::Participant.name, participation: participation) }

      it 'GET#index lists extra public column' do
        user.table_display_for(Event::Participation).update!(selected: %w(person.company_name))

        get :index, params: { group_id: group.id, event_id: course.id }
        expect(dom).to have_checked_field 'Firmenname'
        expect(dom.find('table tbody')).to have_content 'Puzzle ITC Test'
      end

      it 'GET#index lists extra show_full column' do
        user.table_display_for(Event::Participation).update!(selected: %w(person.birthday))

        get :index, params: { group_id: group.id, event_id: course.id }
        expect(dom).to have_checked_field 'Geburtstag'
        expect(dom.find('table tbody')).to have_content '03.03.2003'
      end
    end

    context 'without show_details permission' do
      let!(:event_role) { Fabricate(Event::Course::Role::Participant.name, participation: participation) }

      it 'GET#index lists extra public column' do
        user.table_display_for(Event::Participation).update!(selected: %w(person.company_name))

        get :index, params: { group_id: group.id, event_id: course.id }
        expect(dom).to have_checked_field 'Firmenname'
        expect(dom.find('table tbody')).to have_content 'Puzzle ITC Test'
      end

      it 'GET#index lists extra show_full column, but does not expose data' do
        user.table_display_for(Event::Participation).update!(selected: %w(person.birthday))

        get :index, params: { group_id: group.id, event_id: course.id }
        expect(dom).to have_checked_field 'Geburtstag'
        expect(dom.find('table tbody')).not_to have_content '03.03.2003'
      end
    end

    context 'as event leader' do
      let!(:event_role) { Fabricate(Event::Role::Leader.name, participation: participation) }

      it 'GET#index lists extra public column' do
        user.table_display_for(Event::Participation).update!(selected: %w(person.company_name))

        get :index, params: { group_id: group.id, event_id: course.id }
        expect(dom).to have_checked_field 'Firmenname'
        expect(dom.find('table tbody')).to have_content 'Puzzle ITC Test'
      end

      it 'GET#index lists extra show_full column' do
        user.table_display_for(Event::Participation).update!(selected: %w(person.birthday))

        get :index, params: { group_id: group.id, event_id: course.id }
        expect(dom).to have_checked_field 'Geburtstag'
        expect(dom.find('table tbody')).to have_content '03.03.2003'
      end
    end

  end
end
