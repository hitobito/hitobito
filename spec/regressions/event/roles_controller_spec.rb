# encoding:  utf-8

require 'spec_helper'

describe Event::RolesController, type: :controller do

  let(:course) do
    course = Fabricate(:course, group: groups(:top_layer))
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course
  end
  
  let(:participation) { Fabricate(:event_participation, event: course) }
  
  let(:test_entry) { Fabricate(Event::Role::Leader.name.to_sym, participation: participation) }
  
  let(:new_entry_attrs) do
    { 
      type: Event::Role::AssistantLeader.sti_name
    }
  end
    
  let(:create_entry_attrs) do
    { 
      label: 'Materialchef',
      type: Event::Role::AssistantLeader.sti_name,
      person_id: Fabricate(:person).id
    }
  end
  
  let(:test_entry_attrs) do
    { 
      label: 'Materialchef'
    }
  end
 
  let(:scope_params) { {event_id: course.id} }


  before { sign_in(people(:top_leader)) } 
  before { test_entry }
  
  # Override a few methods to match the actual behavior.
  class << self
    def it_should_redirect_to_show
      it do
        if example.metadata[:action] == :create
          should redirect_to event_participations_path(course.id)
        else
          should redirect_to event_participation_path(course.id, entry.participation_id)
        end
      end 
    end
    
    def it_should_redirect_to_index
      it { should redirect_to event_participations_path(course.id) } 
    end
    
    def it_should_set_attrs
      it "should set params as entry attributes" do
        attrs = test_attrs
        #entry.participation(true)
        #entry.person(true) # reload person on role once a participation is set
        deep_attributes(attrs, entry).should == attrs
      end
    end
  end
  

  include_examples 'crud controller', skip: [%w(index), %w(show), %w(new plain), %w(create html)]


  describe_action :get, :new do
    context ".html", :format => :html do
      it "should raise exception if no type is given", :perform_request => false do
        expect { perform_request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
  
  describe_action :post, :create do
    context ".html", :format => :html do
      let(:params) { { model_identifier => create_entry_attrs } }
      it "creates answers on the go", :perform_request => false do
        expect { perform_request }.to change { Event::Answer.count }.by(2)
      end
      
     context "with valid params" do
        it_should_redirect_to_show
        #it_should_set_attrs
        it_should_have_flash(:notice)
        
        it "should persist entry" do
          entry.should be_persisted
          entry.should be_kind_of(Event::Role::AssistantLeader)
          entry.label.should == create_entry_attrs[:label]
          entry.participation.should be_persisted
          entry.participation.person_id.should == create_entry_attrs[:person_id]
        end
      end
    end
  end
  
  describe_action :delete, :destroy, :id => true do
    context ".html", :format => :html do
      it "should destroy participation for last role", :perform_request => false do
        expect { perform_request }.to change { Event::Participation.count }.by(-1)
      end
    end
  end
end
