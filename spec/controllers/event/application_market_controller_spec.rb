require 'spec_helper'

describe Event::ApplicationMarketController do
  
  let(:event) { Fabricate(:course) }
  
  let(:appl_prio_1)  { Fabricate(:event_application, participation: Fabricate(:event_participation, event: event), 
                                                     priority_1: event) }
  let(:appl_prio_2)  { Fabricate(:event_application, priority_2: event) }
  let(:appl_prio_3)  { Fabricate(:event_application, priority_3: event) }
  let(:appl_waiting) { Fabricate(:event_application, waiting_list: true) }
  let(:appl_other)   { Fabricate(:event_application) }
  let(:appl_other_assigned) do
    participation = Fabricate(:event_participation)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    Fabricate(:event_application, priority_2: event, participation: participation)
  end
  
  let(:appl_participant)  do
    participation = Fabricate(:event_participation, event: event)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    Fabricate(:event_application, participation: participation, priority_2: event)
  end
  
  let(:leader)  do
    participation = Fabricate(:event_participation, event: event)
    Fabricate(Event::Role::Leader.name.to_sym, participation: participation)
  end
  
  before do
    # init required data
    appl_prio_1
    appl_prio_1
    appl_prio_1
    appl_waiting
    appl_other
    appl_other_assigned
    appl_participant
    leader
  end
  
  before { sign_in(people(:top_leader)) }
  
  describe "GET index" do
    
    before { get :index, event_id: event.id }
    
    context "participants" do
      subject { assigns(:participants) }
      
      it "contains participant" do
        should include(appl_participant.participation)
      end
      
      it "does not contain unassigned applications" do
        should_not include(appl_prio_1.participation)
      end
      
      it "does not contain leader" do
        should_not include(leader)
      end
    end
    
    context "applications" do
      subject { assigns(:applications) }
      
      it { should include(appl_prio_1.participation) }
      it { should include(appl_prio_2.participation) }
      it { should include(appl_prio_3.participation) }
      it { should include(appl_waiting.participation) }
      
      it { should_not include(appl_participant.participation) }
      it { should_not include(appl_other.participation) }
      it { should_not include(appl_other_assigned.participation) }
      
    end
    
  end
  
end
