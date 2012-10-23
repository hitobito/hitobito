require 'spec_helper'

describe Event::ApplicationMarketController do
  
  let(:event) { Fabricate(:course) }
  
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
  
  def sign_in(user)
    post person_session_path, person: {email: user.email, password: 'foobar'}
  end
  
  before { sign_in(people(:top_leader)) }
  
  describe "requests are mutually undoable" do
    before do
      get event_application_market_index_path(event.id)
      @participants = assigns(:participants)
      @applications = assigns(:applications)
    end
    
    it "starting from application" do
      post participant_event_application_market_path(event.id, appl_prio_1.id, format: :js)
      delete participant_event_application_market_path(event.id, appl_prio_1.id, format: :js)
      
      get event_application_market_index_path(event.id)
      
      assigns(:applications).should == @applications
      assigns(:participants).should == @participants
    end   
    
    it "starting from application on waiting list" do
      post participant_event_application_market_path(event.id, appl_waiting.id, format: :js)
      delete participant_event_application_market_path(event.id, appl_waiting.id, format: :js)
      
      get event_application_market_index_path(event.id)

      assigns(:applications).should == @applications
      assigns(:participants).should == @participants
    end
        
        
    it "starting from participant" do
      delete participant_event_application_market_path(event.id, appl_participant.id, format: :js)
      post participant_event_application_market_path(event.id, appl_participant.id, format: :js)
      
      get event_application_market_index_path(event.id)
      
      assigns(:applications).should == @applications
      assigns(:participants).should == @participants
    end
  end
  
end
