# encoding: utf-8
require 'spec_helper'

describe Event::QualificationsController, type: :controller do
  
  render_views
  
  let(:event) do
    event = Fabricate(:course, kind: Event::Kind.find_by_short_name('SLK'))
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
  
  let(:dom) { Capybara::Node::Simple.new(response.body) }
  
  before { sign_in(people(:top_leader)) }
  
  before do
    participant_1
    participant_2
  end
  
  describe "GET index" do

    context "in open state" do
      before { get :index, event_id: event.id }
    
      subject { assigns(:participants) }
      
      it { should have(2).items }
      
      it "should have links" do
        dom.should have_selector("#event_participation_#{participant_1.id} td:first a")
      end
      
      it "should have icons" do
        dom.should have_selector("#event_participation_#{participant_1.id} td:first .icon-minus")
      end
      
      it "should not have message" do
        dom.should_not have_content('können die Qualifikationen nicht mehr bearbeitet werden')
      end
    end
    
    context "in closed state" do
      before { event.update_column(:state, 'closed') }
      before { get :index, event_id: event.id }
    
      subject { assigns(:participants) }
      
      it { should have(2).items }
      
      it "should not have links" do
        dom.should_not have_selector("#event_participation_#{participant_1.id} td:first a")
      end
      
      it "should have message" do
        dom.should have_content('können die Qualifikationen nicht mehr bearbeitet werden')
      end
      
      it "should have icons" do
        dom.should have_selector("#event_participation_#{participant_1.id} td:first .icon-minus")
      end
    end
  end
  
  describe 'PUT update' do
    context "in open state" do
      before { put :update, event_id: event.id, id: participant_1.id, format: :js }
    
      subject { Event::Qualifier.new(participant_1).qualifications }
    
      it { should have(1).item }
      it { should render_template('qualification') }
    end
    
    context "in closed state" do
      before { event.update_column(:state, 'closed') }
      before { put :update, event_id: event.id, id: participant_1.id, format: :js }
    
      subject { Event::Qualifier.new(participant_1).qualifications }
    
      it { should have(0).items }
      it { should render_template('qualification') }
    end
  end
  
  describe 'DELETE destroy' do
    before do
      participant_1.person.qualifications.create!(qualification_kind_id: event.kind.qualification_kind_ids.first,
                                                    start_at: event.qualification_date)
    end
    
    context "in open state" do
      before { delete :destroy, event_id: event.id, id: participant_1.id, format: :js }
    
      subject { Event::Qualifier.new(participant_1).qualifications }
    
      it { should have(0).item }
      it { should render_template('qualification') }
    end
    
    context "in closed state" do
      before { event.update_column(:state, 'closed') }
      before { delete :destroy, event_id: event.id, id: participant_1.id, format: :js }
    
      subject { Event::Qualifier.new(participant_1).qualifications }
    
      it { should have(1).items }
      it { should render_template('qualification') }
    end
  end
  
end
