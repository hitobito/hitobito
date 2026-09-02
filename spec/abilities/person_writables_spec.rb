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

  context :see_invisible_from_above do
    let(:role) { Fabricate(Group::TopGroup::InvisiblePeopleManager.name, group: groups(:top_group)) }

    it "has see_invisible_from_above permission" do
      expect(role.permissions).to include(:see_invisible_from_above)
    end

    it "does not return people, as the permission alone grants read access only" do
      visible = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      invisible = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      expect(visible).to be_visible_from_above
      expect(invisible).not_to be_visible_from_above
      is_expected.not_to include(visible.person, invisible.person)
    end

    context "combined with layer_and_below_full" do
      before do
        Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group),
          person: role.person)
      end

      context "own group" do
        it "returns people with visible_from_above=true" do
          other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
          expect(other).to be_visible_from_above
          is_expected.to include(other.person)
        end

        it "returns people with visible_from_above=false" do
          other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
          expect(other).not_to be_visible_from_above
          is_expected.to include(other.person)
        end
      end

      context "lower group" do
        it "returns people with visible_from_above=true" do
          other = Fabricate(Group::BottomLayer::Leader.name.to_sym,
            group: groups(:bottom_layer_one))
          expect(other).to be_visible_from_above
          is_expected.to include(other.person)
        end

        it "returns people with visible_from_above=false" do
          other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
          expect(other).not_to be_visible_from_above
          is_expected.to include(other.person)
        end
      end
    end

    context "combined with layer_and_below_full further down" do
      # Each permission applies downwards from its own role: :see_invisible_from_above from
      # the top layer, :layer_and_below_full from bottom_layer_one. Writing a person needs
      # both of them above her, so bottom_layer_two stays read only.
      before do
        Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one),
          person: role.person)
      end

      it "returns invisible people in the layer_and_below_full subtree" do
        other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
        is_expected.to include(other.person)
      end

      it "does not return people outside that subtree" do
        visible = Fabricate(Group::BottomLayer::Leader.name.to_sym,
          group: groups(:bottom_layer_two))
        invisible = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_two))
        is_expected.not_to include(visible.person, invisible.person)
      end
    end
  end
end
