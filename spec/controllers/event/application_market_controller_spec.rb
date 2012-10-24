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
  
  before { sign_in(people(:top_leader)) }
  
  describe "GET index" do
    
    before { get :index, event_id: event.id }
    
    context "participants" do
      subject { assigns(:participants) }
      
      it { should have(1).items }
      
      it "contains participant" do
        should include(appl_participant)
      end
      
      it "does not contain unassigned applications" do
        should_not include(appl_prio_1)
      end
      
      it "does not contain leader" do
        should_not include(leader)
      end
    end
    
    context "applications" do
      subject { assigns(:applications) }
      
      it { should have(4).items }
      
      it { should include(appl_prio_1) }
      it { should include(appl_prio_2) }
      it { should include(appl_prio_3) }
      it { should include(appl_waiting) }
      
      it { should_not include(appl_participant) }
      it { should_not include(appl_other) }
      it { should_not include(appl_other_assigned) }
      
    end
    
  end
  
  
  describe "POST participant" do
    
    it "creates role" do
      post :add_participant, event_id: event.id, id: appl_prio_1.id, format: :js
      
      appl_prio_1.reload.roles.collect(&:type).should == [event.participant_type.sti_name]
    end
    
    it "shows error on existing participation" do
      other = Fabricate(:course, group: groups(:top_layer))
      Fabricate(:event_participation, event: other, person: appl_prio_1.person, application: Fabricate(:event_application))

      post :add_participant, event_id: other.id, id: appl_prio_1.id, format: :js
      
      should render_template('participation_exists_error')
    end
  end
  
  describe "DELETE participant" do
    before { delete :remove_participant, event_id: event.id, id: appl_participant.id, format: :js }
    
    it "removes role" do
      appl_participant.reload.roles.should_not be_exists
    end
  end
  
  describe "POST waiting_list" do
    before { post :put_on_waiting_list, event_id: event.id, id: appl_prio_1.id, format: :js }
    
    it "sets waiting list flag" do
      appl_prio_1.reload.application.should be_waiting_list
    end
  end
  
  describe "DELETE waiting_list" do
    before { delete :remove_from_waiting_list, event_id: event.id, id: appl_waiting.id, format: :js }
    
    it "sets waiting list flag" do
      appl_waiting.reload.application.should_not be_waiting_list
    end
  end
  
end
