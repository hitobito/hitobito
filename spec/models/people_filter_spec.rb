# == Schema Information
#
# Table name: people_filters
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  group_id   :integer
#  group_type :string(255)
#  kind       :string(255)      not null
#

require 'spec_helper'

describe PeopleFilter do
  
  it "creates RoleTypes on assignment" do
    group = groups(:top_layer)
    filter = group.people_filters.new(name: 'Test', kind: 'layer')
    filter.role_types = ['Group::TopGroup::Leader', 'Group::TopGroup::Member']
    types = filter.related_role_types
    
    types.should have(2).items
    types.first.role_type.should == 'Group::TopGroup::Leader'
   
    filter.should be_valid
    expect { filter.save }.to change { RelatedRoleType.count }.by(2)
  end
  
  it "has group as default kind" do
    PeopleFilter.new.kind.should == 'deep'
  end
  
  
end
