require 'spec_helper'

describe Jubla::Event::Application do

  let(:course)        { Fabricate(:course, group: group) }
  let(:date)  {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
  
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
    let(:course) do 
      event = groups(:city).events.build(name: 'even', contact_id: person.id)
      event.dates.build
      event.save
      event
    end

    its(:contact) { should == person }
  end
end
