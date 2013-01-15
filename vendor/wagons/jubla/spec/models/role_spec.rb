require 'spec_helper'

describe Role do
  
  describe Group::Flock::Leader do
    subject { Group::Flock::Leader }
    
    it { should_not be_affiliate }
    it { should be_visible_from_above }
    it { should_not be_external }
    
    its(:permissions) { should ==  [:layer_full, :contact_data, :approve_applications] }
    
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
  
    it { should be_affiliate }
    it { should_not be_visible_from_above }
    it { should be_external }
    
    its(:permissions) { should ==  [] }
    
    it "may be created for region" do
      role = Fabricate.build(subject.name.to_sym, group: groups(:city))
      role.should be_valid
    end
  end
  
  describe Jubla::Role::Alumnus do
    subject { Jubla::Role::Alumnus }
  
    it { should be_affiliate }
    it { should be_visible_from_above }
    it { should_not be_external }
    
    its(:permissions) { should ==  [:group_read] }
    
    it "may be created for region" do
      role = Fabricate.build(subject.name.to_sym, group: groups(:city))
      role.should be_valid
    end
  end
  
  describe "#all_types" do
    subject { Role.all_types }
    
    it "must have master role as the first item" do
      subject.first.should == Group::FederalBoard::Member
    end
    
    it "must have external role as last item" do
      subject.last.should == Jubla::Role::Alumnus
    end
  end
end
