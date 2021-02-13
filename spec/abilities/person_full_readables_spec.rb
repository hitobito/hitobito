# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PersonFullReadables do
  [:index, :layer_search, :deep_search, :global].each do |action|
    context action do
      let(:action) { action }
      let(:user) { role.person.reload }
      let(:ability) { PersonFullReadables.new(user, action == :index ? group : nil) }

      let(:all_accessibles) do
        people = Person.accessible_by(ability)
        case action
        when :index then people
        when :layer_search then people.in_layer(group.layer_group)
        when :deep_search then people.in_or_below(group.layer_group)
        when :global then people
        end
      end

      subject { all_accessibles }

      context :layer_and_below_full do
        let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

        context "own group" do
          let(:group) { role.group }

          it "may read himself" do
            is_expected.to include(role.person)
          end

          it "may read people in his group" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end

          it "may read external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may read visible people" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
            is_expected.to include(other.person)
          end

          it "may not read external people" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
            is_expected.not_to include(other.person)
          end
        end
      end

      context :layer_and_below_read do
        let(:role) { Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)) }

        context "own group" do
          let(:group) { role.group }

          it "may read himself" do
            is_expected.to include(role.person)
          end

          it "may read people in his group" do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end

          it "may read external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:toppers) }

          it "may read people" do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may read visible people" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may not read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "bottom group" do
          let(:group) { groups(:bottom_group_one_one) }

          it "may not read non-visible" do
            other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :layer_full do
        let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

        context "own group" do
          let(:group) { role.group }

          it "may read himself" do
            is_expected.to include(role.person)
          end

          it "may read people in his group" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end

          it "may read external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may not read visible people" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
            is_expected.not_to include(other.person)
          end

          it "may not read external people" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
            is_expected.not_to include(other.person)
          end
        end
      end

      context :layer_read do
        let(:role) { Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: groups(:top_group)) }

        it "has layer_read permission" do
          expect(role.permissions).to include(:layer_read)
        end

        context "own group" do
          let(:group) { role.group }

          it "may read himself" do
            is_expected.to include(role.person)
          end

          it "may read people in his group" do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end

          it "may read external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:toppers) }

          it "may read people" do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may not read visible people" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "bottom group" do
          let(:group) { groups(:bottom_group_one_one) }

          it "may not read non-visible" do
            other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :group_and_below_full do
        let(:role) { Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: groups(:top_layer)) }

        context "own group" do
          let(:group) { role.group }

          it "may read himself" do
            is_expected.to include(role.person)
          end

          it "may read people in his group" do
            other = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may read external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "below group" do
          let(:group) { groups(:top_group) }

          it "may read people" do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "in below layer" do
          let(:group) { groups(:bottom_layer_one) }

          it "may not read people" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :group_full do
        let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }

        context "own group" do
          let(:group) { role.group }

          it "may read himself" do
            is_expected.to include(role.person)
          end

          it "may read people in his group" do
            other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may read external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:bottom_group_one_two) }

          it "may not read people" do
            other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :contact_data do
        let(:role) { Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers)) }

        context "group in same layer" do
          let(:group) { groups(:top_group) }

          it "may not read people with contact data" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may not read people with contact data" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not get people without contact data" do
            other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :group_read do
        let(:role) { Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers)) }

        it "has only login permission" do
          expect(role.permissions).to eq([:group_read])
        end

        context "own group" do
          let(:group) { role.group }

          if action == :index
            it "may not read himself" do
              is_expected.not_to include(role.person)
            end
          else
            it "may read himself" do
              is_expected.to include(role.person)
            end
          end

          it "may not read people in his group" do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not read external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:top_group) }

          it "may not read people with contact data" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may not read people with contact data" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      describe "no permissions" do
        let(:role) { Fabricate(Role::External.name.to_sym, group: groups(:top_group)) }

        it "has no permissions" do
          expect(role.permissions).to eq([])
        end

        context "own group" do
          let(:group) { role.group }

          if action == :index
            it "may not read himself" do
              is_expected.not_to include(role.person)
            end
          else
            it "may read himself" do
              is_expected.to include(role.person)
            end
          end

          it "may not read people in his group" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not read external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :root do
        let(:user) { people(:root) }

        context "every group" do
          let(:group) { groups(:top_group) }

          it "may read all people" do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may read external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        if action == :global
          it "may read herself" do
            is_expected.to include(user)
          end

          it "may read people outside groups" do
            other = Fabricate(:person)
            is_expected.to include(other)
          end
        end
      end
    end
  end
end
