#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require "spec_helper"

describe PersonWritables do
  let(:user) { role.person.reload }
  let(:ability) { PersonWritables.new(user) }
  let(:accessibles) { Person.accessible_by(ability) }

  subject { accessibles }

  context :group_and_below_full do
    let(:role) { Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: groups(:top_layer)) }

    it "has group_full permission" do
      expect(role.permissions).to include(:group_and_below_full)
    end

    context "own group" do
      let(:group) { role.group }

      it "may not get himself" do
        is_expected.to include(role.person)
      end

      it "may not get people in his group" do
        other = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: group)
        is_expected.to include(other.person)
      end

      it "may not get external people in his group" do
        other = Fabricate(Role::External.name.to_sym, group: group)
        is_expected.to include(other.person)
      end
    end

    context "below group" do
      let(:group) { groups(:top_group) }

      it "may get people" do
        other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
        is_expected.to include(other.person)
      end

      it "may get external people" do
        other = Fabricate(Role::External.name.to_sym, group: group)
        is_expected.to include(other.person)
      end
    end
  end

  context :group_full do
    let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }

    it "has group_full permission" do
      expect(role.permissions).to include(:group_full)
    end

    context "own group" do
      let(:group) { role.group }

      it "may get himself" do
        is_expected.to include(role.person)
      end

      it "may get people in his group" do
        other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: group)
        is_expected.to include(other.person)
      end

      it "may get external people in his group" do
        other = Fabricate(Role::External.name.to_sym, group: group)
        is_expected.to include(other.person)
      end
    end

    context "group in same layer" do
      let(:group) { groups(:bottom_group_one_two) }

      it "may not get people" do
        other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: group)
        is_expected.not_to include(other.person)
      end

      it "may not get external people" do
        other = Fabricate(Role::External.name.to_sym, group: group)
        is_expected.not_to include(other.person)
      end
    end
  end
end
