# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Events::Filter::Groups do
  let(:person) { people(:top_leader) }
  let(:options) { {} }

  let(:scope) { Events::FilteredList.new(person, {}, options).base_scope }

  subject(:filter) { described_class.new(person, params, options, scope) }

  let(:sql) { filter.to_scope.to_sql }
  let(:where_condition) { sql.sub(/.*(WHERE.*)(ORDER BY.*)?$/, '\1') }

  let!(:event_in_another_group) do
    Fabricate(:course, groups: [groups(:bottom_layer_two)])
  end

  context 'has assumptions' do
    let(:params) { {} } # dummy, not needed

    it 'there are ids in a hierarchy' do
      group_ids = person.groups_hierarchy_ids

      expect(group_ids).to match_array [834_963_567, 954_199_476]
    end

    it 'there are 2 courses' do
      expect(Event::Course.count).to eq 2
      expect(Event::Course.list.first.group_ids).to eq [834_963_567]
      expect(Event::Course.list.second.group_ids).to eq [1_037_278_379]
    end
  end

  context 'finds course offerer' do
    let(:params) { {} } # dummy, not really needed

    it 'via primary group' do
      expect(subject.send(:course_group_from_primary_layer).to_a).to eq [groups(:top_layer)]
    end

    it 'via hierarchy' do
      group = groups(:bottom_group_one_one)
      user = Fabricate(Group::BottomGroup::Leader.name.to_s, label: 'foo', group: group).person

      other_filter = described_class.new(user, params, options, scope)

      expect(other_filter.send(:course_group_from_hierarchy).map(&:id)).to eq groups(:bottom_layer_one).hierarchy.map(&:id)
    end
  end

  context 'with the legitimate request to show courses in one group, it' do
    let(:group_id) { groups(:top_layer).id }
    let(:options) { { list_all_courses: true } }
    let(:params) do
      {
        filter: {
          group_ids: [group_id]
        }
      }
    end

    it 'checks the group-id' do
      expect(where_condition)
        .to match(/`groups`\.`id` = #{group_id}/)
    end

    it 'shows only 1 result' do
      expect(subject.to_scope.to_a).to have(1).entries
    end
  end

  context 'with the unallowed request to show courses in one group, it' do
    let(:group_id) { groups(:top_layer).hierarchy.map(&:id) }
    let(:person_hierarchy) { person.groups_hierarchy_ids }
    let(:options) { { list_all_courses: false } }
    let(:params) do
      {
        filter: {
          group_ids: [group_id]
        }
      }
    end

    it 'checks the group-ids' do
      expect(where_condition)
        .to match(/`groups`\.`id` IN \(#{person_hierarchy.join(', ')}\)/)
    end

    it 'shows only 1 result' do
      expect(subject.to_scope.to_a).to have(1).entries
    end
  end

  context 'with no group, but allowed to see all, it' do
    let(:options) { { list_all_courses: true } }
    let(:params) { { filter: {} } }

    it 'does not check group_ids' do
      expect(where_condition).to_not match('group')
    end

    it 'shows all results' do
      expect(subject.to_scope.to_a).to have(2).entries
    end
  end

  context 'with the legitimate request to show courses in multiple groups, it' do
    let(:group_ids) { [groups(:top_layer).id, groups(:bottom_layer_two).id] }
    let(:options) { { list_all_courses: true } }
    let(:params) do
      {
        filter: {
          group_ids: group_ids
        }
      }
    end

    it 'checks the group-id' do
      expect(where_condition)
        .to match(/`groups`\.`id` IN \(#{group_ids.join(', ')}\)/)
    end

    it 'shows only 2 result' do
      expect(subject.to_scope.to_a).to have(2).entries
    end
  end
end
