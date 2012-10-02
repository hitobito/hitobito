require 'spec_helper'

describe Event::ApplicationsController do
  
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
    
    it "builds application with answers" do
      appl = assigns(:application)
      appl.participation.should be_present
      appl.participation.answers.should have(2).items
      appl.participation.person.should == user
    end
  end
  
end
