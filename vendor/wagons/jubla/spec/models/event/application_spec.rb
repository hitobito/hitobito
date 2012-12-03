require 'spec_helper'

describe Jubla::Event::Application do

  let(:course) { Fabricate(:jubla_course, groups: [group]) }
  let(:date)   {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
  
  subject do
    Fabricate(:event_participation, event: course, application: Fabricate(:jubla_event_application)).application
  end


  context "state" do
    let(:group)  { groups(:be) }
    
    its(:contact) { should == groups(:be_agency)}
  end
  
  context "federation" do
    let(:group)  { groups(:ch) }
    
    its(:contact) { should == groups(:federal_board)}
  end
end
