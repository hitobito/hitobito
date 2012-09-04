require 'spec_helper'

describe Person do
    
  let(:person) { role.person }
  subject { person }
  
  context "with one role" do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }
    
    its(:layer_groups) { should == [groups(:top_layer)] }
    
    it "has layer_full permission in top_group" do
      person.groups_with_permission(:layer_full).should == [groups(:top_group)]
    end
  end
  
  
  context "with multiple roles in same layer" do
    let(:role) do
       role1 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
       Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one), person: role1.person)
    end
    
    its(:layer_groups) { should == [groups(:bottom_layer_one)]}
    
    it "has layer_full permission in top_group" do
      person.groups_with_permission(:layer_full).should == [groups(:bottom_layer_one)]
    end
    
    it "has no layer_read permission" do
      person.groups_with_permission(:layer_read).should be_empty
    end
    
    it "only layer role is visible from above" do
      person.groups_where_visible_from_above.should == [groups(:bottom_layer_one)]
    end
  end
  
  context "with multiple roles in different layers" do
    let(:role) do
       role1 = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
       Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one), person: role1.person)
    end
    
    its(:layer_groups) { should have(2).items }
    its(:layer_groups) { should include(groups(:top_layer), groups(:bottom_layer_one)) }
    
    it "has contact_data permission in both groups" do
      person.groups_with_permission(:contact_data).to_set.should == [groups(:top_group), groups(:bottom_layer_one)].to_set
    end
    
    it "both groups are visible from above" do
      person.groups_where_visible_from_above.to_set.should == [groups(:top_group), groups(:bottom_layer_one)].to_set
    end
    
    it "whole hierarchy may view this person" do
      person.above_groups_visible_from.to_set.should == [groups(:top_layer), groups(:top_group), groups(:bottom_layer_one)].to_set
    end
  end
  
  context "with invisible role" do
    let(:role) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)) }
    
    it "is not visible from above" do
      person.groups_where_visible_from_above.should be_empty
    end
  end
end
