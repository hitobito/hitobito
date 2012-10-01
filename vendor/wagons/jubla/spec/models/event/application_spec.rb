require 'spec_helper'

describe Jubla::Event::Application do

  let(:course)        { Fabricate(:course, group: group) }
  let(:participation) { Fabricate(Event::Course::Participation::Participant.name.to_sym) }
  
  subject { Fabricate(:event_application, participation: participation, priority_1: course) }

  context "state" do
    
    let(:group)  { groups(:be) }
    
    its(:contact) { should == groups(:be_agency)}
    
  end
  
  context "federation" do
    
    let(:group)  { groups(:ch) }
    
    its(:contact) { should == groups(:federal_board)}
    
  end

  context "region" do
    let(:person) { Fabricate(:person) }
    let(:course) { group.events.create!(name: 'even', contact: person) }
    let(:group)  { groups(:city) }
    
    its(:contact) { should == person }
    
  end
end
