require 'spec_helper'

describe Jubla::Event::Application do

  let(:course)        { Fabricate(:course, group: group) }
  let(:participation) { Fabricate(:event_participation, event: course) }
  
  subject { Fabricate(:event_application, participation: participation) }

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
