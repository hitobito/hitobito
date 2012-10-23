# encoding:  utf-8

require 'spec_helper'

describe Event::ParticipationsController, type: :controller do

  # always use fixtures with crud controller examples, otherwise request reuse might produce errors
  let(:test_entry) { event_participations(:top) }
  
  let(:course) { test_entry.event }
  
  let(:test_entry_attrs) do
    { 
      additional_information: 'blalbalbalsbla',
      answers_attributes: [
        {answer: 'Halbtax', question_id: event_questions(:top_ov).id},
        {answer: 'nein',    question_id: event_questions(:top_vegi).id},
        {answer: 'Ne du',   question_id: event_questions(:top_more).id},
      ],
      application_attributes: { priority_2_id: nil }
    }
  end

  let(:scope_params) { {event_id: course.id} }
  
  before { sign_in(people(:top_leader)) } 
  

  include_examples 'crud controller', skip: [%w(destroy)]


  describe_action :put, :update, :id => true do
    let(:params) { {model_identifier => test_attrs} }
    
    context ".html", :format => :html do
      context "with valid params", :combine => 'uhv' do
        it "updates answer attributes" do
          as = entry.answers
          as.detect {|a| a.question == event_questions(:top_ov) }.answer.should == 'Halbtax'
          as.detect {|a| a.question == event_questions(:top_vegi) }.answer.should == 'nein'
          as.detect {|a| a.question == event_questions(:top_more) }.answer.should == 'Ne du'
        end
      end
    end
  end

  describe "GET print" do
    subject { response.body }
    let(:person) { Fabricate(:person_with_address) }
    let(:application) { Fabricate(:event_application, priority_1: test_entry.event, participation: test_entry) } 

    let(:dom) { Capybara::Node::Simple.new(response.body) }
    let(:contact_address) { dom.all('address').first }
    let(:particpant_address) { dom.all('address').last }

    before do
      test_entry.event.update_attribute(:contact, person)
      test_entry.update_attribute(:application, application)
    end

    it "renders participant and course contact" do
      get :print, event_id: test_entry.event.id, id: test_entry.id
      contact_address.text.should include person.address
      particpant_address.text.should include "bottom_member@example.com"
    end

    it "redirects users without permission" do
      sign_in(Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one)).person)
      get :print, event_id: test_entry.event.id, id: test_entry.id
      should redirect_to root_url
    end
  end
end
