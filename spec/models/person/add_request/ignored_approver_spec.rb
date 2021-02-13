# encoding: utf-8

# == Schema Information
#
# Table name: person_add_request_ignored_approvers
#
#  id        :integer          not null, primary key
#  group_id  :integer          not null
#  person_id :integer          not null
#

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::AddRequest::IgnoredApprover do
  let(:layer) { groups(:bottom_layer_two) }

  context ".possible_approvers" do
    it "contains all approver roles" do
      r1 = Fabricate(Group::BottomLayer::Leader.name, group: layer).person
      r2 = Fabricate(Group::BottomLayer::LocalGuide.name, group: layer).person
      Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_one), person: r1)
      r3 = Fabricate(Group::BottomLayer::LocalGuide.name, group: layer, deleted_at: 1.year.ago).person

      list = Person::AddRequest::IgnoredApprover.possible_approvers(layer)
      expect(list).to match_array([r1, r2])
    end
  end

  context ".approvers" do
    it "does not contain ignored approvers" do
      r1 = Fabricate(Group::BottomLayer::Leader.name, group: layer).person
      r2 = Fabricate(Group::BottomLayer::LocalGuide.name, group: layer).person
      Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_one), person: r1)
      Person::AddRequest::IgnoredApprover.create!(group: layer, person: r1)

      list = Person::AddRequest::IgnoredApprover.approvers(layer)
      expect(list).to match_array([r2])
    end
  end

  context ".delete_old_ones" do
    it "clears up entries" do
      r1 = Fabricate(Group::BottomLayer::Leader.name, group: layer).person
      Fabricate(Group::BottomLayer::Member.name, group: layer, person: r1)
      r2 = Fabricate(Group::BottomLayer::LocalGuide.name, group: layer, deleted_at: 1.year.ago).person
      r3 = Fabricate(Group::BottomLayer::Member.name, group: layer).person
      r4 = Fabricate(Group::TopGroup::Leader.name, group: groups(:top_group)).person
      Person::AddRequest::IgnoredApprover.create!(group: layer, person: r1)
      Person::AddRequest::IgnoredApprover.create!(group: layer, person: r2)
      Person::AddRequest::IgnoredApprover.create!(group: layer, person: r3)
      Person::AddRequest::IgnoredApprover.create!(group: layer, person: r4)

      expect do
        Person::AddRequest::IgnoredApprover.delete_old_ones
      end.to change { Person::AddRequest::IgnoredApprover.count }.by(-3)
    end
  end
end
