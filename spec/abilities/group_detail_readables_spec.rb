# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe GroupDetailsReadables do

  let(:user)   { role.person.reload }
  let(:ability) { GroupDetailsReadables.new(user) }

  let!(:other_top_group) { Fabricate(Group::TopGroup.sti_name, parent: groups(:top_layer)) }
  let!(:other_layer) { Fabricate(Group::TopLayer.sti_name) }
  let!(:other_group) { Fabricate(Group::TopGroup.sti_name, parent: other_layer) }
  let!(:group_below_one_one) { Fabricate(Group::BottomGroup.sti_name, parent: groups(:bottom_group_one_one)) }

  subject(:accessible_groups) { Group.accessible_by(ability) }

  context :layer_and_below_full do
    let(:role) { Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group)) }

    it 'has layer_and_below_full permission' do
      expect(role.permissions).to include(:layer_and_below_full)
    end

    it 'can index own group' do
      is_expected.to include(role.group)
    end

    it 'can index group in same layer' do
      is_expected.to include(other_top_group)
    end

    it 'can index lower group' do
      is_expected.to include(groups(:bottom_layer_one))
    end

    it 'can not index other layer' do
      is_expected.not_to include(other_layer)
    end

    it 'can not index group in other layer' do
      is_expected.not_to include(other_group)
    end
  end

  context :layer_and_below_read do
    let(:role) { Fabricate(Group::TopGroup::Secretary.sti_name, group: groups(:top_group)) }

    it 'has layer_and_below_read permission' do
      expect(role.permissions).to include(:layer_and_below_read)
    end

    it 'can index own group' do
      is_expected.to include(role.group)
    end

    it 'can index group in same layer' do
      is_expected.to include(other_top_group)
    end

    it 'can index lower group' do
      is_expected.to include(groups(:bottom_layer_one))
    end

    it 'can not index other layer' do
      is_expected.not_to include(other_layer)
    end

    it 'can not index group in other layer' do
      is_expected.not_to include(other_group)
    end
  end

  context :layer_full do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.sti_name, group: groups(:top_group)) }

    it 'has layer_full permission' do
      expect(role.permissions).to include(:layer_full)
    end

    it 'can index own group' do
      is_expected.to include(role.group)
    end

    it 'can index group in same layer' do
      is_expected.to include(other_top_group)
    end

    it 'can not index lower group' do
      is_expected.not_to include(groups(:bottom_layer_one))
    end

    it 'can not index other layer' do
      is_expected.not_to include(other_layer)
    end

    it 'can not index group in other layer' do
      is_expected.not_to include(other_group)
    end
  end

  context :layer_read do
    let(:role) { Fabricate(Group::TopGroup::LocalSecretary.sti_name, group: groups(:top_group)) }

    it 'has layer_read permission' do
      expect(role.permissions).to include(:layer_read)
    end

    it 'can index own group' do
      is_expected.to include(role.group)
    end

    it 'can index group in same layer' do
      is_expected.to include(other_top_group)
    end

    it 'can not index lower group' do
      is_expected.not_to include(groups(:bottom_layer_one))
    end

    it 'can not index other layer' do
      is_expected.not_to include(other_layer)
    end

    it 'can not index group in other layer' do
      is_expected.not_to include(other_group)
    end
  end

  context :group_and_below_full do
    let(:role) { Fabricate(Group::TopGroup::GroupManager.sti_name, group: groups(:top_group)) }

    it 'has group_and_below_full permission' do
      expect(role.permissions).to include(:group_and_below_full)
    end

    it 'can index own group' do
      is_expected.to include(role.group)
    end

    it 'can not index group in same layer' do
      is_expected.not_to include(other_top_group)
    end

    it 'can not index lower group' do
      is_expected.not_to include(groups(:bottom_layer_one))
    end

    it 'can not index other layer' do
      is_expected.not_to include(other_layer)
    end

    it 'can not index group in other layer' do
      is_expected.not_to include(other_group)
    end
  end

  context :group_and_below_read do
    let(:role) { Fabricate(Group::TopGroup::Member.sti_name, group: groups(:top_group)) }

    it 'has group_and_below_read permission' do
      expect(role.permissions).to include(:group_and_below_read)
    end

    it 'can index own group' do
      is_expected.to include(role.group)
    end

    it 'can not index group in same layer' do
      is_expected.not_to include(other_top_group)
    end

    it 'can not index lower group' do
      is_expected.not_to include(groups(:bottom_layer_one))
    end

    it 'can not index other layer' do
      is_expected.not_to include(other_layer)
    end

    it 'can not index group in other layer' do
      is_expected.not_to include(other_group)
    end
  end

  context :group_full do
    let(:role) { Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one)) }

    it 'has group_full permission' do
      expect(role.permissions).to include(:group_full)
    end

    it 'can index own group' do
      is_expected.to include(role.group)
    end

    it 'can not index group in same layer' do
      is_expected.not_to include(groups(:bottom_group_one_two))
    end

    it 'can not index lower group' do
      is_expected.not_to include(group_below_one_one)
    end

    it 'can not index other layer' do
      is_expected.not_to include(other_layer)
    end

    it 'can not index group in other layer' do
      is_expected.not_to include(other_group)
    end
  end

  context :group_read do
    let(:role) { Fabricate(Group::BottomGroup::Member.sti_name, group: groups(:bottom_group_one_one)) }

    it 'has group_read permission' do
      expect(role.permissions).to include(:group_read)
    end

    it 'can index own group' do
      is_expected.to include(role.group)
    end

    it 'can not index group in same layer' do
      is_expected.not_to include(groups(:bottom_group_one_two))
    end

    it 'can not index lower group' do
      is_expected.not_to include(group_below_one_one)
    end

    it 'can not index other layer' do
      is_expected.not_to include(other_layer)
    end

    it 'can not index group in other layer' do
      is_expected.not_to include(other_group)
    end
  end

  context :root do
    let(:user) { people(:root) }

    it 'can index all groups' do
      is_expected.to match_array Group.all
    end
  end

end
