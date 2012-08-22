require 'spec_helper'

describe GroupRoles::ConfigLoader do
  
  context "federation" do
    subject { GroupRoles::GroupType.type(:federation) }
    
    it { should have(6).children }
    it { should have(2).default_children }
    it { should have(3).role_types }
    it { should be_layer }
    
    its(:children) { should include(GroupRoles::GroupType.type(:simple_group)) }
  end
  
  context "flock" do
    subject { GroupRoles::GroupType.type(:flock) }

    it { should have(2).children }
    it { should have(0).default_children }
    it { should have(8).role_types }
    it { should be_layer }
    
    context "leader" do
      let(:leader) { subject.role_type(:leader) }
      
      it "has correct permissions" do
        leader.permissions.should == [:layer_full, :contact_data]
      end
      
      it "is not external" do
        leader.external.should be_false
      end
      
      it "is visible from above" do
        leader.visible_from_above.should be_true
      end
      
      it "is found by class method" do
        GroupRoles::GroupType.role_type('flock-leader').should equal(leader)
      end
    end
  end
  
  context "simple group" do
    subject { GroupRoles::GroupType.type(:simple_group) }
    
    it { should have(1).children }
    it { should have(0).default_children }
    it { should have(5).role_types }
    it { should_not be_layer }
    its(:children) { should include(GroupRoles::GroupType.type(:simple_group)) }
    
    it "includes the common roles" do
      subject.role_types.keys.should include('group_admin')
    end
    
    it "includes the external role" do
      subject.role_types.keys.should include('external')
    end
    
    context "external role" do
      let(:external) { subject.role_type(:external) }
    
      it "is external" do
        external.external.should be_true
      end
      
      it "is not visible from above" do
        external.visible_from_above.should be_false
      end
    end
  end
end
