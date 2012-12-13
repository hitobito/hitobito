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

  context ".order_by_type" do
    it "has correct ordering without group" do
      Group.order_by_type.should == [groups(:top_layer),
                                     groups(:top_group),
                                     groups(:bottom_layer_one),
                                     groups(:bottom_layer_two),
                                     groups(:bottom_group_one_one),
                                     groups(:bottom_group_one_one_one),
                                     groups(:bottom_group_one_two),
                                     groups(:bottom_group_two_one)]
    end

    it "has correct ordering with parent group" do
      parent = groups(:top_layer)
      parent.children.order_by_type(parent).should ==
          [groups(:top_group),
           groups(:bottom_layer_one),
           groups(:bottom_layer_two)]
    end

    it "works without possible groups" do
      parent = groups(:bottom_group_one_two)
      parent.children.order_by_type(parent).should be_empty
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
    let(:top_leader) { roles(:top_leader) }
    let(:top_layer) { groups(:top_layer) }
    let(:bottom_layer) { groups(:bottom_layer_one) }
    let(:bottom_group) { groups(:bottom_group_one_one) }

    context "children" do
      it "destroys self and all children" do
        deleted_ids = bottom_layer.self_and_descendants.collect(&:id)
        expect { bottom_layer.destroy }.to change { Group.without_deleted.count }.by(-4)
        Group.only_deleted.find(:all).collect(&:id).should  =~ deleted_ids
      end

      it "does not destroy anything for root group" do
        expect { top_layer.destroy }.not_to change { Group.count }
      end
    end

    context "role assignments"  do
      it "terminates own roles and all children's roles" do
        Fabricate(Group::BottomLayer::Member.name.to_s, group: bottom_layer)
        Fabricate(Group::BottomGroup::Member.name.to_s, group: bottom_group)
        Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one_one))
        deleted_ids = bottom_layer.self_and_descendants.map {|g| g.roles.collect(&:id) }.flatten
        expect { bottom_layer.destroy }.to change { Role.with_deleted.count }.by(-4)
        #Role.only_deleted.find(:all).collect(&:id).should =~ deleted_ids
      end
    end

    context "events" do
      let(:group) { groups(:bottom_layer_one) }

      it "destroys exclusive events" do
        Fabricate(:event, groups: [group])
        expect { group.destroy }.to change { Event.count }.by(-1)
      end

      it "does not destroy events belonging to other groups as well" do
        Fabricate(:event, groups: [group, groups(:bottom_layer_two)])
        expect { group.destroy }.not_to change { Event.count }
      end

      it "destroys event when removed from association" do
        expect { top_layer.events = [events(:top_event)] }.to change { Event.count }.by(-1)
      end
    end
  end

  context "contacts" do
    let(:contactable) { { address: 'foobar', zip_code: 123, town: 'thun', country: 'ch' } }
    let(:group) { groups(:top_group) }

    subject { group }
    before { group.update_attributes(contactable) }

    context "no contactable but contact info"  do
      its(:contact)   { should be_blank }
      its(:address)   { should eq 'foobar' }
      its(:town)      { should eq 'thun' }
      its(:zip_code)  { should eq 123 }
      its(:country)   { should eq 'ch' }
    end

    context "discards contact info when contactable is set" do
      let(:contact) { Fabricate(:person, other_contactable) }
      let(:other_contactable) { { address: 'barfoo', zip_code: nil } }

      before { group.update_attribute(:contact, contact) }

      its(:address)   { should eq 'barfoo' }
      its(:address?)   { should be_true }
      its(:zip_code?)   { should be_false }
    end

  end


end
