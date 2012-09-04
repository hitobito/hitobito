# == Schema Information
#
# Table name: groups
#
#  id                  :integer          not null, primary key
#  parent_id           :integer
#  lft                 :integer
#  rgt                 :integer
#  name                :string(255)      not null
#  short_name          :string(31)
#  type                :string(255)      not null
#  email               :string(255)
#  address             :string(1024)
#  zip_code            :integer
#  town                :string(255)
#  country             :string(255)
#  contact_id          :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  deleted_at          :datetime
#  bank_account        :string(255)
#  jubla_insurance     :boolean          default(FALSE), not null
#  jubla_full_coverage :boolean          default(FALSE), not null
#  parish              :string(255)
#  kind                :string(255)
#  unsexed             :boolean          default(FALSE), not null
#  clairongarde        :boolean          default(FALSE), not null
#  founding_year       :integer
#  coach               :belongs_to
#  advisor             :belongs_to
#

require 'spec_helper'

describe Group do
    
  it "should load fixtures" do
    groups(:top_layer).should be_present
  end
  
  it "is a valid nested set" do
    Group.should be_valid
  end
  
  context "#hierachy" do
    it "is itself for root group" do
      groups(:top_layer).hierarchy.should == [groups(:top_layer)]
    end
    
    it "contains all ancestors" do
      groups(:bottom_group_one_one).hierarchy.should == [groups(:top_layer), groups(:bottom_layer_one), groups(:bottom_group_one_one)]
    end
  end
    
  context "#layer_groups" do
    it "is itself for top layer" do
      groups(:top_layer).layer_groups.should == [groups(:top_layer)]
    end
    
    it "is next upper layer for top layer group" do
      groups(:top_group).layer_groups.should == [groups(:top_layer)]
    end
    
    it "is all upper layers for regular layer" do
      groups(:bottom_layer_one).layer_groups.should == [groups(:top_layer), groups(:bottom_layer_one)]
    end
  end
  
  context "#layer_group" do
    it "is itself for layer" do
      groups(:top_layer).layer_group.should == groups(:top_layer)
    end
    
    it "is next upper layer for regular group" do
      groups(:bottom_group_one_one).layer_group.should == groups(:bottom_layer_one)
    end
  end
  
  context ".all_types" do
    it "lists all types" do
      Set.new(Group.all_types).should == Set.new([Group::TopLayer, Group::TopGroup, Group::BottomLayer, Group::BottomGroup])
    end
  end
end
