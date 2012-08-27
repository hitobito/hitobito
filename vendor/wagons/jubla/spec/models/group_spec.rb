require 'spec_helper'

describe Group do
  
  describe Group::Federation do
    subject { Group::Federation }
    
    it { should have(6).possible_children }
    it { should have(2).default_children }
    it { should have(3).role_types }
    it { should be_layer }
    
    its(:possible_children) { should include(Group::SimpleGroup) }
  end
  
  describe Group::Flock do
    subject { Group::Flock }

    it { should have(2).possible_children }
    it { should have(0).default_children }
    it { should have(8).role_types }
    it { should be_layer }
    
    describe Group::Flock::Leader do
      let(:leader) { Group::Flock::Leader }
      
      it "has correct permissions" do
        leader.permissions.should == [:layer_full, :contact_data, :login]
      end
      
      it "is not external" do
        leader.external.should be_false
      end
      
      it "is visible from above" do
        leader.visible_from_above.should be_true
      end
    end
  end
  
  describe Group::SimpleGroup do
    subject { Group::SimpleGroup }
    
    it { should have(1).possible_children }
    it { should have(0).default_children }
    it { should have(5).role_types }
    it { should_not be_layer }
    its(:possible_children) { should include(Group::SimpleGroup) }
    
    it "includes the common roles" do
      subject.role_types.should include(Jubla::Role::GroupAdmin)
    end
    
    it "includes the external role" do
      subject.role_types.should include(Jubla::Role::External)
    end
    
    describe Jubla::Role::External do
      let(:external) { Jubla::Role::External }
    
      it "is external" do
        external.external.should be_true
      end
      
      it "is not visible from above" do
        external.visible_from_above.should be_false
      end
    end
  end
end
