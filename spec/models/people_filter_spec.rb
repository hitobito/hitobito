require 'spec_helper'

describe PeopleFilter do
  
  it "creates RoleTypes on assignment" do
    group = groups(:top_layer)
    filter = group.people_filters.new(name: 'Test', kind: 'layer')
    filter.role_types = ['Group::TopGroup::Leader', 'Group::TopGroup::Member']
    types = filter.people_filter_role_types
    
    types.should have(2).items
    types.first.role_type.should == 'Group::TopGroup::Leader'
   
    filter.should be_valid
    expect { filter.save }.to change { PeopleFilter::RoleType.count }.by(2)
  end
  
  it "has group as default kind" do
    PeopleFilter.new.kind.should == 'deep'
  end
  
  
end
