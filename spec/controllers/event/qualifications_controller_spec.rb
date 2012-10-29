require 'spec_helper'

describe Event::QualificationsController do
  
  let(:event) do
    event = Fabricate(:course, kind: event_kinds(:slk))
    event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    event
  end
  
  let(:participant_1) do
    participation = Fabricate(:event_participation, event: event)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    participation
  end
  
  let(:participant_2) do
    participation = Fabricate(:event_participation, event: event)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    participation
  end
  
  before { sign_in(people(:top_leader)) }
  
  it "event kind has one qualification kind" do
    event.kind.qualification_kinds.should == [qualification_kinds(:sl)]
  end
  
  
  describe "GET index" do
    before do
      participant_1
      participant_2
    
      get :index, event_id: event.id
    end
    
    context "entries" do
      subject { assigns(:participants) }
      
      it { should have(2).items }
    end
  end
  
  describe "PUT update" do
    subject { participant_1.qualifications }
    
    context "with one existing qualifications" do
      before do
        participant_1.person.qualifications.create!(qualification_kind_id: event.kind.qualification_kind_ids.first,
                                                    start_at: event.qualification_date)
        put :update, event_id: event.id, id: participant_1.id, format: :js
      end
      
      it { should have(1).item }
      it { should render_template('qualification') }
    end
     
     context "without existing qualifications" do
      before { put :update, event_id: event.id, id: participant_1.id, format: :js }
      
      it { should have(1).item }
      it { should render_template('qualification') }
    end
  end
  
  
  describe "DELETE destroy" do
    
    subject { participant_1.qualifications }
   
    context "without existing qualifications" do
      before do
        delete :destroy, event_id: event.id, id: participant_1.id, format: :js
      end
      
      it { should have(0).items }
      it { should render_template('qualification') }
    end
   
    context "with one existing qualification" do
      before do
        participant_1.person.qualifications.create!(qualification_kind_id: event.kind.qualification_kind_ids.first,
                                                    start_at: event.qualification_date)
        delete :destroy, event_id: event.id, id: participant_1.id, format: :js
      end
      
      it { should have(0).items }
      it { should render_template('qualification') }
    end
  end
end
