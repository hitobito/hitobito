# encoding: UTF-8
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
    let(:dom) { Capybara::Node::Simple.new(response.body) }
    
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

    it "has add button" do
      button = dom.find('.btn-group a')
      button.text.should eq ' Teilnehmer hinzufügen'
      button.should have_css('i.icon-plus')
      button[:href].should eq new_event_participation_path(course, for_someone_else: true)
    end
  end

  
end
