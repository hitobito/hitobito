#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::DeletedPeople do
  context "find deleted people" do
    let(:group) { groups(:top_layer) }
    let(:person) { role.person.reload }
    let(:role) do
      Fabricate(Group::TopLayer::TopAdmin.name, group: group,
        start_on: 1.year.ago)
    end

    let(:child_group) { groups(:bottom_layer_one) }
    let(:child_group_one) { groups(:bottom_group_one_one) }
    let(:child_person) { child_role.person.reload }
    let(:child_role) do
      Fabricate(Group::BottomGroup::Leader.name, group: child_group_one,
        start_on: 1.year.ago)
    end

    context "for single group" do
      context "when group has people without role" do
        before do
          role.update_column(:end_on, 1.day.ago)
        end

        it "finds those people" do
          expect(Group::DeletedPeople.deleted_for(group).first).to eq(person)
        end
        it "doesn't find people with new role" do
          Group::TopLayer::TopAdmin.create(person: person, group: group)

          expect(person.roles.count).to eq 1
          expect(Group::DeletedPeople.deleted_for(group).count).to eq 0
        end

        it "finds people from other group in same layer" do
          child_role.update_column(:end_on, 1.day.ago)
          expect(Group::DeletedPeople.deleted_for(child_group)).to include child_person
        end
      end

      context "when group has no people without role" do
        it "returns empty" do
          expect(Group::DeletedPeople.deleted_for(group).count).to eq 0
        end
      end
    end

    context "for multiple groups" do
      let(:sibling_group) { Fabricate(Group::TopLayer.sti_name.to_sym) }
      let(:sibling_role) do
        Fabricate(Group::TopLayer::TopAdmin.name, group: sibling_group,
          start_on: 1.year.ago)
      end
      let(:all_groups) { [group, sibling_group] }

      context "when group has people without role" do
        before do
          role.update_column(:end_on, 1.day.ago)
        end

        it "finds those people" do
          expect(Group::DeletedPeople.deleted_for_multiple(all_groups).first).to eq(person)
        end

        it "doesn't find people with new role" do
          Group::TopLayer::TopAdmin.create(person: person, group: group)

          expect(person.roles.count).to eq 1
          expect(Group::DeletedPeople.deleted_for_multiple(all_groups).count).to eq 0
        end

        it "finds people from other group in same layer" do
          child_role.update_column(:end_on, 1.day.ago)
          expect(Group::DeletedPeople.deleted_for_multiple([child_group, sibling_group])).to include child_person
        end
      end

      context "when group has no people without role" do
        it "returns empty" do
          expect(Group::DeletedPeople.deleted_for_multiple(all_groups).count).to eq 0
        end
      end
    end
  end

  context "when roles are deleted in different series" do
    let(:group) { groups(:top_layer) }
    let(:bottom_group) { groups(:bottom_layer_one) }
    let(:person) { role_top.person }
    let(:role_top) do
      Fabricate(Group::TopLayer::TopAdmin.name, group: group,
        start_on: 1.year.ago)
    end
    let(:role_bottom) do
      Fabricate(Group::BottomLayer::Leader.name, group: bottom_group, person: person,
        start_on: 1.year.ago)
    end

    before do
      bottom_group.update(parent_id: group.id)
    end

    it "doesnt find when last role deleted in bottom group" do
      role_top.update_column(:end_on, 2.days.ago)
      role_bottom.update_column(:end_on, 1.day.ago)
      expect(Group::DeletedPeople.deleted_for(group).count).to eq 0
    end

    it "find if last deleted role in top group" do
      role_top.update_column(:end_on, 1.day.ago)
      role_bottom.update_column(:end_on, 2.days.ago)
      expect(Group::DeletedPeople.deleted_for(group)).to include person
    end

    it "finds people in child group" do
      role_top.update_column(:end_on, 2.days.ago)
      role_bottom.update_column(:end_on, 1.day.ago)
      expect(Group::DeletedPeople.deleted_for(bottom_group)).to include person
    end

    it "doesnt find when not visible from above" do
      Fabricate(Role::External.name.to_sym, group: bottom_group, person: person,
        start_on: 30.day.ago)
      role_top.destroy
      expect(Group::DeletedPeople.deleted_for(group).count).to eq 0
    end

    it "finds multiple people" do
      end_on = 1.months.ago
      role_top.update_column(:end_on, end_on)
      top2 = Fabricate(Group::TopLayer::TopAdmin.name, group: group,
        start_on: 1.year.ago)
      Fabricate(Group::BottomLayer::Leader.name, group: bottom_group, person: top2.person,
        start_on: 9.months.ago)
      top2.update_column(:end_on, end_on)

      expect(Group::DeletedPeople.deleted_for(group)).to match_array([person])
    end
  end
end
