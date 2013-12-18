# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Group::Merger do

  let(:group1) { groups(:bottom_layer_one) }
  let(:group2) { groups(:bottom_layer_two) }
  let(:other_group) { groups(:top_layer) }

  context 'merge groups' do

    before do
      @person = Fabricate(Group::BottomLayer::Member.name.to_sym,
                          created_at: Date.today - 14, group: group1).person
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: group1)
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: group2)

      Fabricate(:event, groups: [group1])
      Fabricate(:event, groups: [group1])
      Fabricate(:event, groups: [group2])
    end

    it 'creates a new group and merges roles, events' do
      merge = Group::Merger.new(group1, group2, 'foo')
      merge.group2_valid?.should eq true

      merge.merge!

      new_group = Group.find(merge.new_group.id)
      new_group.name.should eq 'foo'
      new_group.type.should eq merge.new_group.type

      new_group.children.count.should eq 3

      new_group.events.count.should eq 3

      new_group.roles.count.should eq 4

      # recent groups
      expect { Group.without_deleted.find(group1.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { Group.without_deleted.find(group2.id) }.to raise_error(ActiveRecord::RecordNotFound)
      group1.children.count.should eq 0
      group2.children.count.should eq 0
      group1.roles.count.should eq 0
      group2.roles.count.should eq 0
      group1.events.count.should eq 2
      group2.events.count.should eq 1

      # the recent role should have been soft-deleted
      @person.reload.roles.only_deleted.count.should eq 1

      # last but not least, check nested set integrity
      Group.should be_valid
    end

    it 'should raise an error if one tries to merge to groups with different types/parent' do
      merge = Group::Merger.new(group1, other_group, 'foo')
      expect { merge.merge! }.to raise_error
    end

    it 'add events from both groups only once' do
      e = Fabricate(:event, groups: [group1, group2])
      merge = Group::Merger.new(group1, group2, 'foo')
      merge.merge!

      e.reload
      e.group_ids.should =~ [group1, group2, merge.new_group].collect(&:id)
    end

    it 'updates layer_group_id for children' do
      merge = Group::Merger.new(group1, group2, 'foo')
      merge.merge!

      new_group = Group.find(merge.new_group.id)
      group1.children.map(&:layer_group_id).uniq.should eq [new_group.id]
      group2.children.map(&:layer_group_id).uniq.should eq [new_group.id]
    end

  end
end
