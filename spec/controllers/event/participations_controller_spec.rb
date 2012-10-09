require 'spec_helper'

describe Event::ParticipationsController do
  
  let(:course) do
    course = Fabricate(:course, group: groups(:top_layer))
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course
  end
  
  let(:user) { people(:top_leader) }
  
  before { sign_in(user) }
  
  context "GET new" do
    before { get :new, event_id: course.id }
    
    it "builds participation with answers" do
      participation = assigns(:participation)
      participation.application.should be_present
      participation.answers.should have(2).items
      participation.person.should == user
    end
  end
    
end
