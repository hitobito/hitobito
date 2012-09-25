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
#  layer_group_id      :integer
#  bank_account        :string(255)
#  jubla_insurance     :boolean          default(FALSE), not null
#  jubla_full_coverage :boolean          default(FALSE), not null
#  parish              :string(255)
#  kind                :string(255)
#  unsexed             :boolean          default(FALSE), not null
#  clairongarde        :boolean          default(FALSE), not null
#  founding_year       :integer
#  coach_id            :integer
#  advisor_id          :integer
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
  
  context "#upper_layer_groups" do
    context "for existing group" do
      it "contains only upper for layer" do
        groups(:bottom_layer_one).upper_layer_groups.should == [groups(:top_layer)]
      end
      
      it "contains only upper for group" do
        groups(:bottom_group_one_one).upper_layer_groups.should == [groups(:top_layer)]
      end
      
      it "is empty for top layer" do
        groups(:top_group).upper_layer_groups.should be_empty
      end
    end
    
    context "for new group" do
      it "contains only upper for layer" do
        group = Group::BottomLayer.new
        group.parent = groups(:top_layer)
        group.upper_layer_groups.should == [groups(:top_layer)]
      end
      
      it "contains only upper for group" do
        group = Group::BottomGroup.new
        group.parent = groups(:bottom_layer_one)
        group.upper_layer_groups.should == [groups(:top_layer)]
      end
      
      it "is empty for top layer" do
        group = Group::TopGroup.new
        group.parent = groups(:top_layer)
        group.upper_layer_groups.should be_empty
      end
    end
  end
  
  context ".all_types" do
    it "lists all types" do
      Set.new(Group.all_types).should == Set.new([Group::TopLayer, Group::TopGroup, Group::BottomLayer, Group::BottomGroup])
    end
  end


  context "#set_layer_group_id" do
    it "sets layer_group_id on group" do
      top_layer = groups(:top_layer) 
      group = Group::TopGroup.new(name: 'foobar')
      group.parent_id = top_layer.id
      group.save!
      group.layer_group_id.should eq top_layer.id
    end

    it "sets layer_group_id on group with default children" do
      group = Group::TopLayer.new(name: 'foobar')
      group.save!
      group.layer_group_id.should eq group.id
      group.children.should be_present
      group.children.first.layer_group_id.should eq group.id
    end
  end

  context "#destroy" do
    let(:bottom_layer_one) { groups(:bottom_layer_one) }

    it "flags group as destroyed" do
      bottom_layer_one.destroy
      Group.only_deleted.find(bottom_layer_one.id).should be_present
    end

    it "destroys all children" do
      bottom_layer_one.children.to_a.size.should eq 2
      expect { bottom_layer_one.destroy }.to change(Group,:count).by(-3)
    end

    it "terminates assigned roles" do
      role = Fabricate(Group::BottomLayer::Member.name.to_s, group: bottom_layer_one )
      expect { bottom_layer_one.destroy }.to change(Role,:count).by(-1)
    end
  end

end
