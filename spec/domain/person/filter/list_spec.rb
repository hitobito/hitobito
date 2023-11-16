# encoding: utf-8

#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::Filter::List do
  let(:top_leader) { people(:top_leader) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_group) { groups(:bottom_group_one_one) }


  context 'top group' do
    it 'empty filter lists top_leader' do
      list = filter_list
      expect(list.all_count).to eq 1
      expect(list.entries.to_a).to have(1).items
      expect(list.entries.collect(&:id)).to eq [top_leader.id]
    end
  end

  context 'bottom group' do
    it 'empty filter returns empty list' do
      list = filter_list(group: bottom_group)
      expect(list.all_count).to eq 0
      expect(list.entries.to_a).to be_empty
    end

    context 'with future role' do
      before do
        Fabricate(:future_role, person: top_leader, group: bottom_group, convert_to: bottom_group.role_types.first)
      end

      it 'does not include future role' do
        list = filter_list(group: bottom_group)
        expect(list.all_count).to eq 0
        expect(list.entries.to_a).to be_empty
      end

      it 'includes future role when explicitly specified via role_type_ids' do
        params = { filters: { role: { role_type_ids: FutureRole.id } } }
        list = filter_list(group: bottom_group, filter: params)
        expect(list.chain).to be_present
        expect(list.all_count).to eq 1
        expect(list.entries.to_a).to be_empty
      end
    end
  end

  context 'archived groups' do
    let(:root) { people(:root) }
    before do
      top_group.archive!
      expect(top_group.archived_at).to_not be_nil
    end

    it 'empty filter with range deep does not list people from archived groups' do
      list = filter_list(person: root)
      expect(list.all_count).to eq 0
      expect(list.entries.to_a).to have(0).items
    end

    it 'empty filter with range layer does not list people from archived groups' do
      list = filter_list(person: root)
      expect(list.all_count).to eq 0
      expect(list.entries.to_a).to have(0).items
    end

    it 'empty filter with empty range does not list people from archived groups' do
      list = filter_list(person: root)
      expect(list.all_count).to eq 0
      expect(list.entries.to_a).to have(0).items
    end
  end

  def filter_list(person: top_leader, group: top_group, filter: PeopleFilter.new(name: 'name'))
    described_class.new(group, person, filter)
  end
end
