require 'spec_helper_request'

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
  
  before { sign_in }
  
  describe "requests are mutually undoable", js: true do
    before do
      visit event_application_market_index_path(event.id)
      
      @participants = find('#participants').text
      @applications = find('#applications').text
    end
    
    context "waiting_list" do
      it "starting from application" do
        appl_id = "event_participation_#{appl_prio_1.id}"
        find("#applications ##{appl_id} td:last").should have_selector('.icon-minus')
        
        find("#applications ##{appl_id}").click_link('Warteliste')
        find("#applications ##{appl_id} td:last").should have_selector('.icon-ok')
        
        find("#applications ##{appl_id}").click_link('Warteliste')
        find("#applications ##{appl_id} td:last").should have_selector('.icon-minus')
        
        visit event_application_market_index_path(event.id)
        
        find('#participants').text == @participants
        find('#applications').text == @applications
      end   
      
      it "starting from application on waiting list" do
        appl_id = "event_participation_#{appl_waiting.id}"
        find("#applications ##{appl_id} td:last").should have_selector('.icon-ok')
        
        find("#applications ##{appl_id}").click_link('Warteliste')
        find("#applications ##{appl_id} td:last").should have_selector('.icon-minus')
        
        find("#applications ##{appl_id}").click_link('Warteliste')
        find("#applications ##{appl_id} td:last").should have_selector('.icon-ok')
        
        
        visit event_application_market_index_path(event.id)
  
        find('#participants').text == @participants
        find('#applications').text == @applications
      end
    end
        
    context "participant" do
      it "starting from application" do
        appl_id = "event_participation_#{appl_prio_1.id}"
        
        find("#applications ##{appl_id} td:first a").trigger('click')
        should_not have_selector("#applications ##{appl_id}")
        find("#participants tr:last").should have_content(appl_prio_1.person.to_s)
        
        find("#participants ##{appl_id} td:last a").trigger('click')
        should_not have_selector("#participants ##{appl_id}")
        find("#applications tr:last").should have_content(appl_prio_1.person.to_s)
        
        visit event_application_market_index_path(event.id)
        
        find('#participants').text == @participants
        find('#applications').text == @applications
      end   
      
      it "starting from application on waiting list" do
        appl_id = "event_participation_#{appl_waiting.id}"
        
        find("#applications ##{appl_id} td:first a").trigger('click')
        find("#participants tr:last").should have_content(appl_waiting.person.to_s)
        should_not have_selector("#applications ##{appl_id}")
        
        find("#participants ##{appl_id} td:last a").trigger('click')
        should_not have_selector("#participants ##{appl_id}")
        find("#applications tr:last").should have_content(appl_waiting.person.to_s)
        
        visit event_application_market_index_path(event.id)
        
        find('#participants').text == @participants
        find('#applications').text == @applications
      end
      
      it "starting from participant" do
        appl_id = "event_participation_#{appl_participant.id}"
        
        find("#participants ##{appl_id} td:last a").trigger('click')
        should_not have_selector("#participants ##{appl_id}")
        find("#applications tr:last").should have_content(appl_participant.person.to_s)
        
        find("#applications ##{appl_id} td:first a").trigger('click')
        find("#participants tr:last").should have_content(appl_participant.person.to_s)
        should_not have_selector("#applications ##{appl_id}")
        
        
        visit event_application_market_index_path(event.id)
        
        find('#participants').text == @participants
        find('#applications').text == @applications
      end
    
    end
  end
  
end
