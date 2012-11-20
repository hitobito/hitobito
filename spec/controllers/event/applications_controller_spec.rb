require 'spec_helper'

describe Event::ApplicationsController do
  
  let(:event) { events(:top_course) }
  let(:group) { event.groups.first }
  let(:group_leader) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person }
  let(:participant) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person }
  let(:participation) do
    Fabricate(:event_participation, 
              event: event, 
              person: participant,
              application: Fabricate(:event_application))
  end
  let(:application) do
    participation.application
  end
        
  context "group leader" do
    before { sign_in(group_leader) }
    
    describe 'PUT approve' do
      before { put :approve, group_id: group.id, event_id: event.id, id: application.id }
      
      it { should redirect_to(group_event_participation_path(group, event, participation)) }
      
      it "sets flash" do
        flash[:notice].should =~ /freigegeben/
      end
      
      it "approves application" do
        application.reload.should be_approved
        application.reload.should_not be_rejected
      end
    end
    
    describe 'DELETE reject' do
      before { delete :reject, group_id: group.id, event_id: event.id, id: application.id }
      
      it { should redirect_to(group_event_participation_path(group, event, participation)) }
      
      it "sets flash" do
        flash[:notice].should =~ /abgelehnt/
      end
      
      it "rejects application" do
        application.reload.should be_rejected
        application.reload.should_not be_approved
      end
    end
  end
  
  
  context "as top leader" do
    let(:user) { people(:top_leader) }
    
    before { sign_in(user) }
    
    describe 'PUT approve' do
      before { put :approve, group_id: group.id, event_id: event.id, id: application.id }
      it { should redirect_to(root_url) }
    end
    
    describe 'DELETE reject' do
      before { delete :reject, group_id: group.id, event_id: event.id, id: application.id }
      it { should redirect_to(root_url) }
    end
  end
  
end
