require 'spec_helper'

describe Role do
  
  describe Group::Flock::Leader do
    subject { Group::Flock::Leader }
    
    it { should_not be_external }
    it { should be_visible_from_above }
    
    its(:permissions) { should ==  [:layer_full, :contact_data, :login] }
    
    it "may be created for flock" do
      role = Fabricate.build(subject.name.to_sym, group: groups(:bern))
      role.should be_valid
    end
    
    it "may not be created for region" do
      role = Fabricate.build(subject.name.to_sym, group: groups(:city))
      role.should_not be_valid
      role.should have(1).error_on(:type)
    end
  end
  
  describe Jubla::Role::External do
    subject { Jubla::Role::External }
  
    it { should be_external }
    it { should_not be_visible_from_above }
    
    its(:permissions) { should ==  [] }
    
    it "may be created for region" do
      role = Fabricate.build(subject.name.to_sym, group: groups(:city))
      role.should be_valid
    end
  end
  
  describe "#all_types" do
    subject { Role.all_types}
    
    it "must have master role as the first item" do
      subject.first.should == Group::FederalBoard::Member
    end
    
    it "must have external role as last item" do
      subject.last.should == Jubla::Role::External
    end
  end
  
end
