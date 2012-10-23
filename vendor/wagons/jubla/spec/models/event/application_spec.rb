require 'spec_helper'

describe Jubla::Event::Application do

  let(:course)        { Fabricate(:course, group: group) }
  
  subject do
    Fabricate(:event_participation, event: course, application: Fabricate(:event_application)).application
  end


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
    let(:course) { groups(:city).events.create!(name: 'even', contact: person) }
    
    its(:contact) { should == person }
  end
end
