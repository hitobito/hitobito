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
    before { put :update, event_id: event.id, id: participant_1.id, format: :js }
    
    subject { participant_1.qualifications }
    
    it { should have(1).item }
    it { should render_template('qualification') }
  end
  
  
  describe "DELETE destroy" do
    before do
      participant_1.person.qualifications.create!(qualification_kind_id: event.kind.qualification_kind_ids.first,
                                                  start_at: event.qualification_date)
      delete :destroy, event_id: event.id, id: participant_1.id, format: :js
    end
    
    subject { participant_1.qualifications }
    
    it { should have(0).items }
    it { should render_template('qualification') }
  end
end
