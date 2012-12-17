require 'spec_helper'

describe Group::Merger do

  let(:group1) { groups(:bottom_layer_one) }
  let(:group2) { groups(:bottom_layer_two) }

  context "merge groups" do

    before do
      
      @person = Fabricate(Group::BottomLayer::Member.name.to_sym, 
                         created_at: Date.today - 14, group: group1).person
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: group1)
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: group2)

      Fabricate(:event, groups: [group1])
      Fabricate(:event, groups: [group1])
      Fabricate(:event, groups: [group2])

      @new_group = Group::Merger.new(group1, group2, 'foo').new_group

    end

    it "creates a new group and merges roles, events" do

      new_group = Group.find(@new_group.id)
      new_group.name.should eq @new_group.name
      new_group.type.should eq @new_group.type

      new_group.children.count.should eq 3

      new_group.events.count.should eq 3

      new_group.roles.count.should eq 4

      expect { Group.find(group1.id) }.to raise_error(ActiveRecord::RecordNotFound) 
      expect { Group.find(group2.id) }.to raise_error(ActiveRecord::RecordNotFound) 

      # the recent role should have been soft-deleted
      @person.reload.roles.only_deleted.count.should eq 1

    end

  end
  
end
