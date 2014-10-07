# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'


# Specs for listing and searching people
describe PersonAccessibles do

  [:index, :layer_search, :deep_search, :global].each do |action|
    context action do
      let(:action) { action }
      let(:user)   { role.person.reload }
      let(:ability) { PersonAccessibles.new(user, action == :index ? group : nil) }

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

      describe :layer_and_below_full do
        let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

        it 'has layer_and_below_full permission' do
          role.permissions.should include(:layer_and_below_full)
        end

        context 'own group' do
          let(:group) { role.group }

          it 'may get himself' do
            should include(role.person)
          end

          it 'may get people in his group' do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
            should include(other.person)
          end

          it 'may get external people in his group' do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            should include(other.person)
          end
        end

        context 'lower group' do
          let(:group) { groups(:bottom_layer_one) }

          it 'may get visible people' do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
            should include(other.person)
          end

          it 'may not get external people' do
            other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
            should_not include(other.person)
          end
        end
      end


      describe :layer_and_below_read do
        let(:role) { Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)) }

        it 'has layer_and_below_read permission' do
          role.permissions.should include(:layer_and_below_read)
        end

        context 'own group' do
          let(:group) { role.group }

          it 'may get himself' do
            should include(role.person)
          end

          it 'may get people in his group' do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
            should include(other.person)
          end

          it 'may get external people in his group' do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            should include(other.person)
          end
        end

        context 'group in same layer' do
          let(:group) { groups(:toppers) }

          it 'may get people' do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            should include(other.person)
          end

          it 'may get external people' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should include(other.person)
          end
        end

        context 'lower group' do
          let(:group) { groups(:bottom_layer_one) }

          it 'may get visible people' do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            should include(other.person)
          end

          it 'may not get external people' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

        context 'bottom group' do
          let(:group) { groups(:bottom_group_one_one) }

          it 'may not get non-visible' do
            other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

      end


      describe :layer_full do
        let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

        it 'has layer_full permission' do
          role.permissions.should include(:layer_full)
        end

        context 'own group' do
          let(:group) { role.group }

          it 'may get himself' do
            should include(role.person)
          end

          it 'may get people in his group' do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
            should include(other.person)
          end

          it 'may get external people in his group' do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            should include(other.person)
          end
        end

        context 'lower group' do
          let(:group) { groups(:bottom_layer_one) }

          it 'may not get visible people' do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
            should_not include(other.person)
          end

          it 'may not get external people' do
            other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
            should_not include(other.person)
          end
        end
      end


      describe :layer_read do
        let(:role) { Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: groups(:top_group)) }

        it 'has layer_read permission' do
          role.permissions.should include(:layer_read)
        end

        context 'own group' do
          let(:group) { role.group }

          it 'may get himself' do
            should include(role.person)
          end

          it 'may get people in his group' do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
            should include(other.person)
          end

          it 'may get external people in his group' do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            should include(other.person)
          end
        end

        context 'group in same layer' do
          let(:group) { groups(:toppers) }

          it 'may get people' do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            should include(other.person)
          end

          it 'may get external people' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should include(other.person)
          end
        end

        context 'lower group' do
          let(:group) { groups(:bottom_layer_one) }

          it 'may not get visible people' do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            should_not include(other.person)
          end

          it 'may not get external people' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

        context 'bottom group' do
          let(:group) { groups(:bottom_group_one_one) }

          it 'may not get non-visible' do
            other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

      end


      describe :group_full do
        let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }

        it 'has group_full permission' do
          role.permissions.should include(:group_full)
        end

        context 'own group' do
          let(:group) { role.group }

          it 'may get himself' do
            should include(role.person)
          end

          it 'may get people in his group' do
            other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
            should include(other.person)
          end

          it 'may get external people in his group' do
            other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one))
            should include(other.person)
          end
        end

        context 'group in same layer' do
          let(:group) { groups(:bottom_group_one_two) }

          it 'may not get people' do
            other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: group)
            should_not include(other.person)
          end

          it 'may not get external people' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

      end

      describe :contact_data do
        let(:role) { Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers)) }

        it 'has contact data permission' do
          role.permissions.should include(:contact_data)
        end

        context 'own group' do
          let(:group) { role.group }

          it 'may get himself' do
            should include(role.person)
          end

          it 'may get people in his group' do
            other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: group)
            should include(other.person)
          end

          it 'may get external people in his group' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should include(other.person)
          end
        end

        context 'group in same layer' do
          let(:group) { groups(:top_group) }

          it 'may get people with contact data' do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
            should include(other.person)
          end

          it 'may not get external people' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

        context 'lower group' do
          let(:group) { groups(:bottom_layer_one) }

          it 'may get people with contact data' do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            should include(other.person)
          end

          it 'may not get people without contact data' do
            other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: group)
            should_not include(other.person)
          end

          it 'may not get external people' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

      end


      describe :group_read do
        let(:role) { Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers)) }

        it 'has only login permission' do
          role.permissions.should == [:group_read]
        end

        context 'own group' do
          let(:group) { role.group }

          it 'may get himself' do
            should include(role.person)
          end

          it 'may get people in his group' do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            should include(other.person)
          end

          it 'may get external people in his group' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should include(other.person)
          end
        end

        context 'group in same layer' do
          let(:group) { groups(:top_group) }

          it 'may not get people with contact data' do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
            should_not include(other.person)
          end

          it 'may not get external people' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

        context 'lower group' do
          let(:group) { groups(:bottom_layer_one) }

          it 'may not get people with contact data' do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            should_not include(other.person)
          end

          it 'may not get external people' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

      end


      describe 'no permissions' do
        let(:role) { Fabricate(Role::External.name.to_sym, group: groups(:top_group)) }

        it 'has no permissions' do
          role.permissions.should == []
        end

        context 'own group' do
          let(:group) { role.group }

          if action == :index
            it 'may not get himself' do
              should_not include(role.person)
            end
          else
            it 'may get himself' do
              should include(role.person)
            end
          end

          it 'may not get people in his group' do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
            should_not include(other.person)
          end

          it 'may not get external people in his group' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

        context 'group in same layer' do
          let(:group) { groups(:toppers) }

          it 'may not get people with contact data' do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

        context 'lower group' do
          let(:group) { groups(:bottom_layer_one) }

          it 'may not get people with contact data' do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            should_not include(other.person)
          end
        end

      end

      describe :root do
        let(:user) { people(:root) }

        context 'every group' do
          let(:group) { groups(:top_group) }

          it 'may get all people' do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: group)
            should include(other.person)
          end

          it 'may get external people' do
            other = Fabricate(Role::External.name.to_sym, group: group)
            should include(other.person)
          end
        end

        if action == :global
          it 'may get herself' do
            should include(user)
          end

          it 'may get people outside groups' do
            other = Fabricate(:person)
            should include(other)
          end
        end

      end

    end
  end
end
