require 'spec_helper'

describe Role do
  
  subject { Role }

  its(:all_types) { should have(7).items }
  
  its(:visible_types) { should have(5).items }
  
  its(:visible_types) { should_not include(Group::BottomGroup::Member) }
  
  it "should have two types with permission :layer_full" do
    Role.types_with_permission(:layer_full).to_set.should == [Group::TopGroup::Leader, Group::BottomLayer::Leader].to_set
  end
  
  it "should have no types with permission :not_existing" do
    Role.types_with_permission(:not_existing).should be_empty
  end
end
