# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JsonApi::RoleReadables do
  let(:group) { groups(:top_group) }
  let(:person) { Fabricate(:person) }
  let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: group, person: person) }

  let(:user) { Fabricate(:person) }

  subject { described_class.new(user) }

  context "when having `show_full` permission on person" do
    let!(:user_role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: group, person: user) }

    it do
      is_expected.to be_able_to(:read, role)
    end
  end

  context "when missing `show_full` permission on person and read permission on group" do
    let!(:user_role) { Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers), person: user) }

    it { is_expected.not_to be_able_to(:read, role) }
  end

  context "with group_read" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: group, person: person) }
    let!(:user_role) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: group, person: user) }

    let(:role_in_other_group) do
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two), person: person)
    end
    let(:role_in_subgroup) do
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one_one), person: person)
    end

    it "may read roles in the own group" do
      is_expected.to be_able_to(:read, role)
    end

    it "may not read roles of the same person in other groups" do
      is_expected.not_to be_able_to(:read, role_in_other_group)
    end

    it "may not read roles in subgroups" do
      is_expected.not_to be_able_to(:read, role_in_subgroup)
    end

    it "lists only roles in the own group" do
      expect(Role.accessible_by(subject)).to include(role, user_role)
      expect(Role.accessible_by(subject)).not_to include(role_in_other_group, role_in_subgroup)
    end
  end

  context "with group_and_below_read" do
    # Created before the ability, which reads the nested set boundaries of the groups
    let!(:subgroup) { Fabricate(Group::TopGroup.name.to_sym, parent: group) }
    let!(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: group, person: person) }
    let!(:role_in_subgroup) { Fabricate(Group::TopGroup::Member.name.to_sym, group: subgroup, person: person) }
    let!(:role_in_other_group) do
      Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers), person: person)
    end
    let!(:user_role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group, person: user) }

    it "may read roles in the own group and below" do
      is_expected.to be_able_to(:read, role)
      is_expected.to be_able_to(:read, role_in_subgroup)
    end

    it "may not read roles of the same person in other groups" do
      is_expected.not_to be_able_to(:read, role_in_other_group)
    end

    it "lists only roles in the own group and below" do
      expect(Role.accessible_by(subject)).to include(role, role_in_subgroup)
      expect(Role.accessible_by(subject)).not_to include(role_in_other_group)
    end
  end

  context "without group based permission" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: group, person: person) }
    let!(:user_role) { Fabricate(Group::BottomGroup::NoPermissions.name.to_sym, group: group, person: user) }

    it { is_expected.not_to be_able_to(:read, role) }
  end
end
