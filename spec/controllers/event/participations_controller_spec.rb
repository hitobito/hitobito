# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationsController do

  let(:group) { groups(:top_layer) }

  let(:other_course) do
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
                                         priority_2: Fabricate(:course, kind: course.kind)))
    p.answers.create!(question_id: course.questions[0].id, answer: 'juhu')
    p.answers.create!(question_id: course.questions[1].id, answer: 'blabla')
    p
  end

  let(:user) { people(:top_leader) }

  before do
    user.qualifications << Fabricate(:qualification, qualification_kind: qualification_kinds(:gl),
                                                     start_at: course.dates.first.start_at)
    sign_in(user)
    other_course
  end


  context 'GET show' do

    context 'for same event' do
      before { get :show, group_id: group.id, event_id: course.id, id: participation.id }

      it 'has two answers' do
        assigns(:answers).should have(2).items
      end

      it 'has application' do
        assigns(:application).should be_present
      end
    end

    context 'for other event' do
      before { get :show, group_id: group.id, event_id: other_course.id, id: participation.id }

      it 'has participation' do
        assigns(:participation).should eq(participation)
      end
    end

  end


  context 'GET new' do
    before { get :new, group_id: group.id, event_id: event.id }

    context 'for course with priorization' do
      let(:event) { course }

      it 'builds participation with answers' do
        participation = assigns(:participation)
        participation.application.should be_present
        participation.application.priority_1.should == course
        participation.answers.should have(2).items
        participation.person.should == user
        assigns(:priority_2s).collect(&:id).should =~ [events(:top_course).id, other_course.id]
        assigns(:alternatives).collect(&:id).should =~ [events(:top_course).id, course.id, other_course.id]
      end
    end

    context 'for event without application' do
      let(:event) do
        event = Fabricate(:event, groups: [group])
        event.questions << Fabricate(:event_question, event: event)
        event.questions << Fabricate(:event_question, event: event)
        event.dates << Fabricate(:event_date, event: event)
        event
      end

      it 'builds participation with answers' do
        participation = assigns(:participation)
        participation.application.should be_blank
        participation.answers.should have(2).items
        participation.person.should == user
        assigns(:priority_2s).should be_nil
      end
    end

  end

  context 'GET index' do
    before { @leader, @participant = *create(Event::Role::Leader, course.participant_type) }

    it 'lists particpant and leader group by default' do
      get :index, group_id: group.id, event_id: course.id
      assigns(:participations).should eq [@leader, @participant]
    end

    it 'lists only leader_group' do
      get :index, group_id: group.id, event_id: course.id, filter: :teamers
      assigns(:participations).should eq [@leader]
    end

    it 'lists only participant_group' do
      get :index, group_id: group.id, event_id: course.id, filter: :participants
      assigns(:participations).should eq [@participant]
    end

    it 'generates pdf labels' do
      get :index, group_id: group, event_id: course.id, label_format_id: label_formats(:standard).id, format: :pdf

      @response.content_type.should == 'application/pdf'
      people(:top_leader).reload.last_label_format.should == label_formats(:standard)
    end

    it 'exports csv files' do
      get :index, group_id: group, event_id: course.id, format: :csv

      @response.content_type.should == 'text/csv'
      @response.body.should =~ /^Vorname;Nachname/
      @response.body.should =~ %r{^#{@leader.person.first_name};#{@leader.person.last_name}}
      @response.body.should =~ %r{^#{@participant.person.first_name};#{@participant.person.last_name}}
    end

    it 'renders email addresses with additional ones' do
      e1 = Fabricate(:additional_email, contactable: @participant.person, mailings: true)
      Fabricate(:additional_email, contactable: @leader.person, mailings: false)
      get :index, group_id: group, event_id: course.id, format: :email
      @response.body.should == "#{@leader.person.email},#{@participant.person.email},#{e1.email}"
    end

    def create(*roles)
      roles.map do |role_class|
        role = Fabricate(:event_role, type: role_class.sti_name)
        Fabricate(:event_participation, event: course, roles: [role], active: true)
      end
    end
  end


  context 'POST create' do

    context 'for current user' do
      let(:person)  { Fabricate(:person, email: 'anybody@example.com') }
      let(:app1)    { Fabricate(:person, email: 'approver1@example.com') }
      let(:app2)    { Fabricate(:person, email: 'approver2@example.com') }

      before do
        # create one person with two approvers
        Fabricate(Group::BottomLayer::Leader.name.to_sym, person: app1, group: groups(:bottom_layer_one))
        Fabricate(Group::BottomLayer::Leader.name.to_sym, person: app2, group: groups(:bottom_layer_one))
        Fabricate(Group::BottomGroup::Leader.name.to_sym, person: person, group: groups(:bottom_group_one_one))

        person.qualifications << Fabricate(:qualification, qualification_kind: qualification_kinds(:sl))
      end

      it 'creates confirmation job' do
        expect do
          post :create, group_id: group.id, event_id: course.id, event_participation: {}
        end.to change { Delayed::Job.count }.by(1)
        flash[:notice].should include 'Für die definitive Anmeldung musst du diese Seite über <i>Drucken</i> ausdrucken, '
        flash[:notice].should include 'unterzeichnen und per Post an die entsprechende Adresse schicken.'
      end

      it 'creates participant role for non course events' do
        post :create, group_id: group.id, event_id: Fabricate(:event).id, event_participation: {}
        participation = assigns(:participation)
        participation.roles.should have(1).item
        role = participation.roles.first
        flash[:notice].should include 'Teilnahme von <i>Top Leader</i> in <i>Eventus</i> wurde erfolgreich erstellt.'
        flash[:notice].should include 'Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an.'
        role.participation.should eq participation.model
      end

    end

    context 'other user' do
      let(:bottom_member) { people(:bottom_member) }
      let(:participation) { assigns(:participation) }

      it 'top leader can create participation for bottom member' do
        post :create, group_id: group.id, event_id: course.id, event_participation: { person_id: bottom_member.id }
        participation.should be_present
        participation.persisted?.should be_true
        participation.should be_active
        participation.roles.pluck(:type).should == [Event::Course::Role::Participant.sti_name]
        should redirect_to group_event_participation_path(group, course, participation)
      end

      it 'bottom member can not create participation for top leader' do
        sign_in(bottom_member)
        expect do
          post :create, group_id: group.id, event_id: course.id, event_participation: { person_id: user.id }
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  context 'preconditions' do
    before { user.qualifications.first.destroy }

    { new: :get, create: :post }.each do |action, method|
      before { send(method, action, group_id: group.id, event_id: course.id) }

      context "#{method.upcase} #{action}"  do
        it 'redirects to event#show' do
          should redirect_to group_event_path(group, course)
        end
        it 'sets flash message' do
          flash[:alert].last.should =~ /Folgende Qualifikationen fehlen: Group Lead/
        end
      end
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
        post :create, group_id: event.groups.first.id,
                      event_id: event.id,
                      event_participation: { answers_attributes: answers_attributes }
        assigns(:participation).answers.first.answer.should eq 'GA, Halbtax'
      end
    end

    context 'PUT #update' do
      let!(:participation) { Fabricate(:event_participation, event: event, person: user) }
      let(:values) { ['0'] }
      let(:answer) { participation.answers.build }
      let(:answers_attributes) { { '0' => { 'question_id' => question.id, 'answer' => ['0'], id: answer.id } } }

      before do
        answer.answer = 'GA, Halbtax'
        answer.question = question
        answer.save
      end

      it 'handles resetting of multiple choice answers' do
        participation.answers.first.answer.should eq 'GA, Halbtax'
        put :update, group_id: event.groups.first.id,
                     event_id: event.id, id: participation.id,
                     event_participation: { answers_attributes: answers_attributes }
        participation.reload.answers.first.answer.should be_nil
      end
    end
  end
end
