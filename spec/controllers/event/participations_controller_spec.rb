# encoding: utf-8
require 'spec_helper'

describe Event::ParticipationsController do
  
  let(:other_course) do 
    other = Fabricate(:course, group: course.group, kind: course.kind)
    other.dates << Fabricate(:event_date, event: other, start_at: course.dates.first.start_at)
    other
  end
  
  let(:course) do
    course = Fabricate(:course, group: groups(:top_layer), priorization: true)
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
  
  before { sign_in(user); other_course }
  

  context "GET show" do
    
    before { get :show, event_id: course.id, id: participation.id }
    
    it "has two answers" do
      assigns(:answers).should have(2).items
    end
    
    it "has application" do
      assigns(:application).should be_present
    end
  end


  context "GET new" do
    before { get :new, event_id: event.id }
    
    context "for course with priorization" do
      let(:event) { course }
      
      it "builds participation with answers" do
        participation = assigns(:participation)
        participation.application.should be_present
        participation.application.priority_1.should == course
        participation.answers.should have(2).items
        participation.person.should == user
        assigns(:priority_2s).collect(&:id).should =~ [other_course.id]
        assigns(:alternatives).collect(&:id).should =~ [course.id, other_course.id]
      end
    end
    
    context "for event without application" do
      let(:event) do
        event = Fabricate(:event, group: groups(:top_layer))
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
      get :index, event_id: course.id
      assigns(:participations).should eq [@leader, @participant]
    end

    it "lists only leader_group" do
      get :index, event_id: course.id, filter: :leaders
      assigns(:participations).should eq [@leader]
    end

    it "lists only participant_group" do
      get :index, event_id: course.id, filter: :participants
      assigns(:participations).should eq [@participant]
    end

    def create(*roles)
      roles.map do |role_class|
        role = Fabricate(:event_role, type: role_class.name.to_sym)
        Fabricate(:event_participation, event: course, roles: [role], active: true)
      end
    end
  end


  context "POST create" do
    let(:person)  { Fabricate(:person) }
    let(:app1)    { Fabricate(:person) }
    let(:app2)    { Fabricate(:person) }
    
    before do
      # create one person with two approvers
      Fabricate(Group::BottomLayer::Leader.name.to_sym, person: app1, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::Leader.name.to_sym, person: app2, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.name.to_sym, person: person, group: groups(:bottom_group_one_one))
    end
    
    context "without approvers" do
      context "without requiring approval" do
        it "sends confirmation email" do
          course.update_column(:requires_approval, false)
          post :create, event_id: course.id
          
          participation = assigns(:participation)
          should redirect_to event_participation_path(course, participation)
          ActionMailer::Base.deliveries.should have(1).item
          last_email.subject.should == 'Bestätigung der Anmeldung'
        end
      end
      
      context "with event requiring approval" do
        it "does only send approval" do
          course.update_column(:requires_approval, true)
          post :create, event_id: course.id
          
          ActionMailer::Base.deliveries.should have(1).item
          last_email.subject.should == 'Bestätigung der Anmeldung'
        end
      end
    end
    
    context "with approvers" do
      context "without requiring approval" do
        it "does not send approval if not required" do
          course.update_column(:requires_approval, false)
          sign_in(person)
          post :create, event_id: course.id
          
          ActionMailer::Base.deliveries.should have(1).items
          last_email.subject.should == 'Bestätigung der Anmeldung'
        end
      end
      
      context "with event requiring approval" do
        it "sends confirmation and approvals to approvers" do
          course.update_column(:requires_approval, true)
          sign_in(person)
          post :create, event_id: course.id
          ActionMailer::Base.deliveries.should have(2).items
          
          first_email = ActionMailer::Base.deliveries.first
          last_email.to.should == [app1.email, app2.email]
          last_email.subject.should == 'Freigabe einer Kursanmeldung'
          first_email.subject.should == 'Bestätigung der Anmeldung'
        end
      end
    end
    
  end
  
    
end
