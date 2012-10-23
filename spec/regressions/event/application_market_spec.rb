require 'spec_helper'

describe Event::ApplicationMarketController, type: :controller do
  
  render_views
  
  let(:course) { events(:top_course) }
  
  before do
    Fabricate(:event_participation, event: course, application: Fabricate(:event_application, priority_1: course))
    Fabricate(:event_participation, application: Fabricate(:event_application, priority_2: course))
    Fabricate(:event_participation, application: Fabricate(:event_application, priority_3: course))
    
    Fabricate(course.participant_type.name.to_sym, 
              participation: Fabricate(:event_participation, 
                                       event: course, 
                                       application: Fabricate(:event_application)))
    Fabricate(course.participant_type.name.to_sym, 
              participation: Fabricate(:event_participation, 
                                       event: course, 
                                       application: Fabricate(:event_application)))

    sign_in(people(:top_leader))
  end
  
  
  describe 'GET index' do
    
    before { get :index, event_id: course.id }
    
    it { should render_template('index') }
    
    it "has participants" do
      assigns(:participants).should have(2).items
    end
    
    it "has applications" do
      assigns(:applications).should have(3).items
    end
    
    it "has event" do
      assigns(:event).should == course
    end
  end
  
end
