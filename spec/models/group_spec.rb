# encoding: utf-8
# == Schema Information
#
# Table name: groups
#
#  id             :integer          not null, primary key
#  parent_id      :integer
#  lft            :integer
#  rgt            :integer
#  name           :string(255)      not null
#  short_name     :string(31)
#  type           :string(255)      not null
#  email          :string(255)
#  address        :string(1024)
#  zip_code       :integer
#  town           :string(255)
#  country        :string(255)
#  contact_id     :integer
#  created_at     :datetime
#  updated_at     :datetime
#  deleted_at     :datetime
#  layer_group_id :integer
#  creator_id     :integer
#  updater_id     :integer
#  deleter_id     :integer
#

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require 'spec_helper'

describe Group do

  it 'should load fixtures' do
    groups(:top_layer).should be_present
  end

  it 'is a valid nested set' do
    Group.should be_valid
  end

  context 'alphabetic order' do
    context 'on insert' do
      it 'at the beginning' do
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: 'AAA', parent_id: parent.id)
        group.save!
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
          'AAA', 'Bottom One', 'Bottom Two', 'TopGroup', 'Toppers']
      end

      it 'at the beginning with same name' do
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: 'Bottom One', parent_id: parent.id)
        group.save!
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
          'Bottom One', 'Bottom One', 'Bottom Two', 'TopGroup', 'Toppers']
      end

      it 'in the middle' do
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: 'Frosch', parent_id: parent.id)
        group.save!
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'Bottom Two', 'Frosch', 'TopGroup', 'Toppers']
      end

      it 'in the middle with same name' do
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: 'Bottom Two', parent_id: parent.id)
        group.save!
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'Bottom Two', 'Bottom Two', 'TopGroup', 'Toppers']
      end

      it 'at the end' do
        parent = groups(:top_layer)
        group = Group::TopGroup.new(name: 'ZZ Top', parent_id: parent.id)
        group.save!
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'Bottom Two', 'TopGroup', 'Toppers', 'ZZ Top']
      end

      it 'at the end with same name' do
        parent = groups(:top_layer)
        group = Group::TopGroup.new(name: 'Toppers', parent_id: parent.id)
        group.save!
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'Bottom Two', 'TopGroup', 'Toppers', 'Toppers']
      end
    end

    context 'on update' do
      it 'at the beginning' do
        groups(:bottom_layer_two).update_attributes!(name: 'AAA')
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
          'AAA', 'Bottom One', 'TopGroup', 'Toppers']
      end

      it 'at the beginning with same name' do
        groups(:bottom_layer_two).update_attributes!(name: 'Bottom One')
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
          'Bottom One', 'Bottom One', 'TopGroup', 'Toppers']
      end

      it 'in the middle keeping position right' do
        groups(:bottom_layer_two).update_attributes!(name: 'Frosch')
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'Frosch', 'TopGroup', 'Toppers']
      end

      it 'in the middle keeping position left' do
        groups(:bottom_layer_two).update_attributes!(name: 'Bottom P')
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'Bottom P', 'TopGroup', 'Toppers']
      end

      it 'in the middle moving right' do
        groups(:bottom_layer_two).update_attributes!(name: 'TopGzzz')
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'TopGroup', 'TopGzzz', 'Toppers']
      end

      it 'in the middle moving left' do
        groups(:top_group).update_attributes!(name: 'Bottom P')
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'Bottom P', 'Bottom Two', 'Toppers']
      end

      it 'in the middle with same name' do
        groups(:bottom_layer_two).update_attributes!(name: 'TopGroup')
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'TopGroup', 'TopGroup', 'Toppers']
      end

      it 'at the end' do
        groups(:bottom_layer_two).update_attributes!(name: 'ZZ Top')
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'TopGroup', 'Toppers', 'ZZ Top']
      end

      it 'at the end with same name' do
        groups(:bottom_layer_two).update_attributes!(name: 'Toppers')
        groups(:top_layer).children.order(:lft).collect(&:name).should eq [
         'Bottom One', 'TopGroup', 'Toppers', 'Toppers']
      end
    end
  end

  context '#hierachy' do
    it 'is itself for root group' do
      groups(:top_layer).hierarchy.should == [groups(:top_layer)]
    end

    it 'contains all ancestors' do
      groups(:bottom_group_one_one).hierarchy.should == [groups(:top_layer), groups(:bottom_layer_one), groups(:bottom_group_one_one)]
    end
  end

  context '#layer_hierarchy' do
    it 'is itself for top layer' do
      groups(:top_layer).layer_hierarchy.should == [groups(:top_layer)]
    end

    it 'is next upper layer for top layer group' do
      groups(:top_group).layer_hierarchy.should == [groups(:top_layer)]
    end

    it 'is all upper layers for regular layer' do
      groups(:bottom_layer_one).layer_hierarchy.should == [groups(:top_layer), groups(:bottom_layer_one)]
    end
  end

  context '#layer_group' do
    it 'is itself for layer' do
      groups(:top_layer).layer_group.should == groups(:top_layer)
    end

    it 'is next upper layer for regular group' do
      groups(:bottom_group_one_one).layer_group.should == groups(:bottom_layer_one)
    end
  end

  context '#upper_layer_hierarchy' do
    context 'for existing group' do
      it 'contains only upper for layer' do
        groups(:bottom_layer_one).upper_layer_hierarchy.should == [groups(:top_layer)]
      end

      it 'contains only upper for group' do
        groups(:bottom_group_one_one).upper_layer_hierarchy.should == [groups(:top_layer)]
      end

      it 'is empty for top layer' do
        groups(:top_group).upper_layer_hierarchy.should be_empty
      end
    end

    context 'for new group' do
      it 'contains only upper for layer' do
        group = Group::BottomLayer.new
        group.parent = groups(:top_layer)
        group.upper_layer_hierarchy.should == [groups(:top_layer)]
      end

      it 'contains only upper for group' do
        group = Group::BottomGroup.new
        group.parent = groups(:bottom_layer_one)
        group.upper_layer_hierarchy.should == [groups(:top_layer)]
      end

      it 'is empty for top layer' do
        group = Group::TopGroup.new
        group.parent = groups(:top_layer)
        group.upper_layer_hierarchy.should be_empty
      end
    end
  end

  context '#sister_groups_with_descendants' do
    subject { group.sister_groups_with_descendants.to_a }

    context 'for root' do
      let(:group) { groups(:top_layer) }

      it 'contains all groups' do
        should =~ Group.all
      end
    end

    context 'for group without children or sisters' do
      let(:group) { groups(:top_group) }

      it 'only contains self' do
        should == [group]
      end
    end

    context 'for layer' do
      let(:group) { groups(:bottom_layer_one) }

      it 'contains other layers and their descendants' do
        should =~ [group.self_and_descendants, groups(:bottom_layer_two).self_and_descendants].flatten
      end
    end

    context 'for group' do
      let(:group) { groups(:bottom_group_one_one) }

      it 'contains other groups and their descendants' do
        should =~ [group, groups(:bottom_group_one_one_one), groups(:bottom_group_one_two)]
      end
    end
  end

  context '.all_types' do
    it 'lists all types' do
      Group.all_types =~ [Group::TopLayer, Group::TopGroup, Group::BottomLayer, Group::BottomGroup, Group::GlobalGroup]
    end
  end

  context '.order_by_type' do
    it 'has correct ordering without group' do
      Group.order_by_type.should == [groups(:top_layer),
                                     groups(:top_group),
                                     groups(:bottom_layer_one),
                                     groups(:bottom_layer_two),
                                     groups(:bottom_group_one_one),
                                     groups(:bottom_group_one_one_one),
                                     groups(:bottom_group_one_two),
                                     groups(:bottom_group_two_one),
                                     groups(:toppers)]
    end

    it 'has correct ordering with parent group' do
      parent = groups(:top_layer)
      parent.children.order_by_type(parent).should ==
          [groups(:top_group),
           groups(:bottom_layer_one),
           groups(:bottom_layer_two),
           groups(:toppers)]
    end

    it 'works without possible groups' do
      parent = groups(:bottom_group_one_two)
      parent.children.order_by_type(parent).should be_empty
    end
  end


  context '#set_layer_group_id' do
    it 'sets layer_group_id on group' do
      top_layer = groups(:top_layer)
      group = Group::TopGroup.new(name: 'foobar')
      group.parent_id = top_layer.id
      group.save!
      group.layer_group_id.should eq top_layer.id
    end

    it 'sets layer_group_id on group with default children' do
      group = Group::TopLayer.new(name: 'foobar')
      group.save!
      group.layer_group_id.should eq group.id
      group.children.should be_present
      group.children.first.layer_group_id.should eq group.id
    end
  end

  context '#destroy' do
    let(:top_leader) { roles(:top_leader) }
    let(:top_layer) { groups(:top_layer) }
    let(:bottom_layer) { groups(:bottom_layer_one) }
    let(:bottom_group) { groups(:bottom_group_one_two) }

    it 'destroys self' do
      expect { bottom_group.destroy }.to change { Group.without_deleted.count }.by(-1)
      Group.only_deleted.collect(&:id).should  =~ [bottom_group.id]
      Group.should be_valid
    end

    it 'hard destroys self' do
      expect { bottom_group.destroy! }.to change { Group.with_deleted.count }.by(-1)
      Group.should be_valid
    end

    it 'protects group with children' do
      expect { bottom_layer.destroy }.not_to change { Group.without_deleted.count }
    end

    it 'does not destroy anything for root group' do
      expect { top_layer.destroy }.not_to change { Group.count }
    end

    context 'role assignments'  do
      it 'terminates own roles' do
        role = Fabricate(Group::BottomGroup::Member.name.to_s, group: bottom_group)
        deleted_ids = bottom_group.roles.collect(&:id)
        # role is deleted permanantly as it is less than Settings.role.minimum_days_to_archive old
        expect { bottom_group.destroy }.to change { Role.with_deleted.count }.by(-1)
      end
    end

    context 'events' do
      let(:group) { groups(:bottom_group_one_two) }

      it 'does not destroy exclusive events on soft destroy' do
        Fabricate(:event, groups: [group])
        expect { group.destroy }.not_to change { Event.count }
      end

      it 'destroys exclusive events on hard destroy' do
        Fabricate(:event, groups: [group])
        expect { group.destroy! }.to change { Event.count }.by(-1)
      end

      it 'does not destroy events belonging to other groups as well' do
        Fabricate(:event, groups: [group, groups(:bottom_group_one_one)])
        expect { group.destroy }.not_to change { Event.count }
      end

      it 'destroys event when removed from association' do
        expect { top_layer.events = [events(:top_event)] }.to change { Event.count }.by(-1)
      end
    end
  end

  context 'contacts' do
    let(:contactable) { { address: 'foobar', zip_code: 123, town: 'thun', country: 'ch' } }
    let(:group) { groups(:top_group) }

    subject { group }
    before { group.update_attributes(contactable) }

    context 'no contactable but contact info'  do
      its(:contact)   { should be_blank }
      its(:address)   { should eq 'foobar' }
      its(:town)      { should eq 'thun' }
      its(:zip_code)  { should eq 123 }
      its(:country)   { should eq 'ch' }
    end

    context 'discards contact info when contactable is set' do
      let(:contact) { Fabricate(:person, other_contactable) }
      let(:other_contactable) { { address: 'barfoo', zip_code: nil } }

      before { group.update_attribute(:contact, contact) }

      its(:address)   { should eq 'barfoo' }
      its(:address?)   { should be_true }
      its(:zip_code?)   { should be_false }
    end

  end


end
