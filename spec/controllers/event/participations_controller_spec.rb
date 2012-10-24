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
    p = Fabricate(:event_participation, event: course, application: Fabricate(:event_application, priority_2: Fabricate(:course, kind: course.kind)))
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
  

  context "POST create" do
    specify do
      post :create, event_id: other_course.id
      participation = assigns(:participation)
      should redirect_to event_participation_path(other_course, participation)
      last_email.should be_present
    end
  end
  
    
end
