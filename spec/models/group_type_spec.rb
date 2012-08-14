require 'spec_helper'

describe GroupType do
  
  context "federation" do
    subject { GroupType.type(:federation) }
    
    it { should have(6).children }
    it { should have(2).default_children }
    it { should have(2).role_types }
    it { should be_layer }
    
    its(:children) { should include(GroupType.type(:simple_group)) }
  end
  
  context "flock" do
    subject { GroupType.type(:flock) }

    it { should have(2).children }
    it { should have(0).default_children }
    it { should have(9).role_types }
    it { should be_layer }
    
    context "leader" do
      it "has correct permissions" do
        subject.permissions(:leader).should == [:layer_full, :contact_data]
      end
      
      it "is found by class method" do
        GroupType.permissions('flock-leader').should equal(subject.permissions(:leader))
      end
    end
  end
  
  context "simple group" do
    subject { GroupType.type(:simple_group) }
    
    it { should have(1).children }
    it { should have(0).default_children }
    it { should have(5).role_types }
    it { should_not be_layer }
    its(:children) { should include(GroupType.type(:simple_group)) }
    
    it "includes the common roles" do
      subject.role_types.keys.should include('group_admin')
    end
  end
end
