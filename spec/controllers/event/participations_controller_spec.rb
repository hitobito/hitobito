# encoding: utf-8
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
  

  context "GET show" do
    
    before { get :show, group_id: group.id, event_id: course.id, id: participation.id }
    
    it "has two answers" do
      assigns(:answers).should have(2).items
    end
    
    it "has application" do
      assigns(:application).should be_present
    end
  end


  context "GET new" do
    before { get :new, group_id: group.id, event_id: event.id }
    
    context "for course with priorization" do
      let(:event) { course }
      
      it "builds participation with answers" do
        participation = assigns(:participation)
        participation.application.should be_present
        participation.application.priority_1.should == course
        participation.answers.should have(2).items
        participation.person.should == user
        assigns(:priority_2s).collect(&:id).should =~ [events(:top_course).id, other_course.id]
        assigns(:alternatives).collect(&:id).should =~ [events(:top_course).id, course.id, other_course.id]
      end
    end
    
    context "for event without application" do
      let(:event) do
        event = Fabricate(:event, groups: [group])
        event.questions << Fabricate(:event_question, event: event)
        event.questions << Fabricate(:event_question, event: event)
        event.dates << Fabricate(:event_date, event: event)
        event
      end
      
      it "builds participation with answers" do
        participation = assigns(:participation)
        participation.application.should be_blank
        participation.answers.should have(2).items
        participation.person.should == user
        assigns(:priority_2s).should be_nil
      end
    end

  end

  context "GET index" do
    before { @leader, @participant = *create(Event::Role::Leader, course.participant_type) }
    
    it "lists particpant and leader group by default" do
      get :index, group_id: group.id, event_id: course.id
      assigns(:participations).should eq [@leader, @participant]
    end

    it "lists only leader_group" do
      get :index, group_id: group.id, event_id: course.id, filter: :teamers
      assigns(:participations).should eq [@leader]
    end

    it "lists only participant_group" do
      get :index, group_id: group.id, event_id: course.id, filter: :participants
      assigns(:participations).should eq [@participant]
    end
  
    it "generates pdf labels" do
      get :index, group_id: group, event_id: course.id, label_format_id: label_formats(:standard).id, format: :pdf
      
      @response.content_type.should == 'application/pdf'
      people(:top_leader).reload.last_label_format.should == label_formats(:standard)
    end

    it "exports csv files" do
      get :index, group_id: group, event_id: course.id, format: :csv

      @response.content_type.should == 'text/csv'
      @response.body.should =~ /^Vorname;Nachname/
      @response.body.should =~ %r{^#{@leader.person.first_name};#{@leader.person.last_name}}
      @response.body.should =~ %r{^#{@participant.person.first_name};#{@participant.person.last_name}}
    end

    def create(*roles)
      roles.map do |role_class|
        role = Fabricate(:event_role, type: role_class.name.to_sym)
        Fabricate(:event_participation, event: course, roles: [role], active: true)
      end
    end
  end


  context "POST create" do
    
    context "for current user" do
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
      
      it "creates confirmation job" do
        expect { post :create, group_id: group.id, event_id: course.id }.to change { Delayed::Job.count }.by(1)
      end
        
      it "creates participant role for non course events" do
        post :create, group_id: group.id, event_id: Fabricate(:event).id
        participation = assigns(:participation)
        participation.roles.should have(1).item
        role = participation.roles.first
        role.participation.should eq participation.model
      end
    end

    context "other user" do
      let(:bottom_member) { people(:bottom_member) }
      let(:participation) { assigns(:participation) }
  
      it "top leader can create participation for bottom member" do
        post :create, group_id: group.id, event_id: course.id, event_participation: { person_id: bottom_member.id }
        participation.should be_present
        participation.persisted?.should be_true
        participation.should be_active
        participation.roles.pluck(:type).should == [Event::Course::Role::Participant.sti_name]
        should redirect_to group_event_participation_path(group, course, participation)
      end
  
      it "bottom member can not create participation for top leader" do
        sign_in(bottom_member)
        post :create, group_id: group.id, event_id: course.id, event_participation: { person_id: user.id }
        participation.person.should eq user
        participation.persisted?.should be_false
        should redirect_to root_url
      end
    end
  end

  context "preconditions" do
    before { user.qualifications.first.destroy } 

    {new: :get, create: :post}.each do |action, method| 
      before { send(method, action, group_id: group.id, event_id: course.id) } 

      context "#{method.upcase} #{action}"  do
        it "redirects to event#show" do
          should redirect_to group_event_path(group, course)
        end
        it "sets flash message" do
          flash[:alert].last.should =~ /Folgende Qualifikationen fehlen: Group Lead/
        end
      end
    end

  end
end
