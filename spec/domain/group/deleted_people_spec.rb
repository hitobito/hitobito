# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Group::DeletedPeople do

  context 'find deleted people' do
    let(:group)         { groups(:top_layer) }
    let(:person)        { role.person.reload }
    let(:role) do
      Fabricate(Group::TopLayer::TopAdmin.name, group: group,
                created_at: Time.zone.now - 1.year)
    end

    let(:child_group)      { groups(:bottom_layer_one) }
    let(:child_group_one)  { groups(:bottom_group_one_one) }
    let(:child_person)     { child_role.person.reload }
    let(:child_role) do
      Fabricate(Group::BottomGroup::Leader.name, group: child_group_one,
                created_at: Time.zone.now - 1.year)
    end

    context 'for single group' do
      context 'when group has people without role' do
        before do
          role.destroy
        end

        it 'finds those people' do
          expect(Group::DeletedPeople.deleted_for(group).first).to eq(person)
        end
        it 'doesn\'t find people with new role' do
          Group::TopLayer::TopAdmin.create(person: person, group: group)

          expect(person.roles.count).to eq 1
          expect(Group::DeletedPeople.deleted_for(group).count).to eq 0
        end

        it 'finds people from other group in same layer' do
          child_role.destroy
          expect(Group::DeletedPeople.deleted_for(child_group)).to include child_person
        end
      end

      context 'when group has no people without role' do
        it 'returns empty' do
          expect(Group::DeletedPeople.deleted_for(group).count).to eq 0
        end
      end
    end

    context 'for multiple groups' do
      let(:sibling_group) { Fabricate(Group::TopLayer.sti_name.to_sym) }
      let(:sibling_role) do
        Fabricate(Group::TopLayer::TopAdmin.name, group: sibling_group,
                  created_at: Time.zone.now - 1.year)
      end
      let(:all_groups) { [group, sibling_group] }

      context 'when group has people without role' do
        before do
          role.destroy
        end

        it 'finds those people' do
          expect(Group::DeletedPeople.deleted_for_multiple(all_groups).first).to eq(person)
        end

        it 'doesn\'t find people with new role' do
          Group::TopLayer::TopAdmin.create(person: person, group: group)

          expect(person.roles.count).to eq 1
          expect(Group::DeletedPeople.deleted_for_multiple(all_groups).count).to eq 0
        end

        it 'finds people from other group in same layer' do
          child_role.destroy
          expect(Group::DeletedPeople.deleted_for_multiple([child_group, sibling_group])).to include child_person
        end
      end

      context 'when group has no people without role' do
        it 'returns empty' do
          expect(Group::DeletedPeople.deleted_for_multiple(all_groups).count).to eq 0
        end
      end
    end
  end

  context 'when roles are deleted in different series' do

    let(:group)         { groups(:top_layer) }
    let(:bottom_group)  { groups(:bottom_layer_one) }
    let(:person)        { role_top.person }
    let(:role_top) do
      Fabricate(Group::TopLayer::TopAdmin.name, group: group,
                created_at: Time.zone.now - 1.year)
    end
    let(:role_bottom) do
      Fabricate(Group::BottomLayer::Leader.name, group: bottom_group, person: person,
                created_at: Time.zone.now - 1.year)
    end

    before do
      bottom_group.update(parent_id: group.id)
    end

    it 'doesnt find when last role deleted in bottom group' do
      role_top.destroy
      role_top.update_column(:deleted_at, 1.hour.ago)
      role_bottom.destroy
      expect(Group::DeletedPeople.deleted_for(group).count).to eq 0
    end

    it 'find if last deleted role in top group' do
      role_bottom.destroy
      role_bottom.update_column(:deleted_at, 1.hour.ago)
      role_top.destroy
      expect(Group::DeletedPeople.deleted_for(group)).to include person
    end

    it 'finds people in child group' do
      role_top.destroy
      role_top.update_column(:deleted_at, 1.hour.ago)
      role_bottom.destroy
      expect(Group::DeletedPeople.deleted_for(bottom_group)).to include person
    end

    it 'doesnt find when not visible from above' do
      role_bottom = Fabricate(Role::External.name.to_sym, group: bottom_group, person: person,
                              created_at: DateTime.current - 30.day)
      role_top.destroy
      expect(Group::DeletedPeople.deleted_for(group).count).to eq 0
    end

    it 'finds multiple people' do
      del = 1.months.ago
      role_top.destroy
      role_top.update!(deleted_at: del)
      top2 = Fabricate(Group::TopLayer::TopAdmin.name, group: group,
                created_at: Time.zone.now - 1.year)
      Fabricate(Group::BottomLayer::Leader.name, group: bottom_group, person: top2.person,
                created_at: Time.zone.now - 9.months)
      top2.destroy
      top2.update!(deleted_at: del)

      expect(Group::DeletedPeople.deleted_for(group)).to match_array([person])
    end

  end
end

