# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::Filter::Role do

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:range) { nil }
  let(:role_types) { [] }
  let(:role_type_ids_string) { role_types.collect(&:id).join(Person::Filter::Role::ID_URL_SEPARATOR) }
  let(:list_filter) do
    Person::Filter::List.new(group,
                             user,
                             range: range,
                             filters: {
                               role: {role_type_ids: role_type_ids_string }
                             })
  end

  let(:entries) { list_filter.entries }

  before do
    @tg_member = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
    Fabricate(:phone_number, contactable: @tg_member, number: '123', label: 'Privat', public: true)
    Fabricate(:phone_number, contactable: @tg_member, number: '456', label: 'Mobile', public: false)
    Fabricate(:social_account, contactable: @tg_member, name: 'facefoo', label: 'Facebook', public: true)
    Fabricate(:social_account, contactable: @tg_member, name: 'skypefoo', label: 'Skype', public: false)
    # duplicate role
    Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group), person: @tg_member)
    @tg_extern = Fabricate(Role::External.name.to_sym, group: groups(:top_group)).person

    @bl_leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
    @bl_extern = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one)).person

    @bg_leader = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
    @bg_member = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
  end

  context 'group' do
    it 'loads all members of a group' do
      expect(entries.collect(&:id)).to match_array([user, @tg_member].collect(&:id))
    end

    it 'contains all existing members' do
      expect(entries.size).to eq(list_filter.all_count)
    end

    context 'with external types' do
      let(:role_types) { [Role::External] }
      it 'loads externs of a group' do
        expect(entries.collect(&:id)).to match_array([@tg_extern].collect(&:id))
      end

      it 'contains all existing externals' do
        expect(entries.size).to eq(list_filter.all_count)
      end
    end

    context 'with specific types' do
      let(:role_types) { [Role::External, Group::TopGroup::Member] }
      it 'loads selected roles of a group' do
        expect(entries.collect(&:id)).to match_array([@tg_member, @tg_extern].collect(&:id))
      end

      it 'contains all existing people' do
        expect(entries.size).to eq(list_filter.all_count)
      end
    end
  end

  context 'layer' do
    let(:group) { groups(:bottom_layer_one) }
    let(:range) { 'layer' }

    context 'with layer and below full' do
      let(:user) { @bl_leader }

      it 'loads group members when no types given' do
        expect(entries.collect(&:id)).to match_array([people(:bottom_member), @bl_leader].collect(&:id))
        expect(list_filter.all_count).to eq(2)
      end

      context 'with specific types' do
        let(:role_types) { [Group::BottomGroup::Member, Role::External] }

        it 'loads selected roles of a group when types given' do
          expect(entries.collect(&:id)).to match_array([@bg_member, @bl_extern].collect(&:id))
          expect(list_filter.all_count).to eq(2)
        end
      end
    end

  end

  context 'deep' do
    let(:group) { groups(:top_layer) }
    let(:range) { 'deep' }

    it 'loads group members when no types are given' do
      expect(entries.collect(&:id)).to match_array([])
    end

    context 'with specific types' do
      let(:role_types) { [Group::BottomGroup::Leader, Role::External] }

      it 'loads selected roles of a group when types given' do
        expect(entries.collect(&:id)).to match_array([@bg_leader, @tg_extern].collect(&:id))
      end

      it 'contains not all existing people' do
        expect(entries.size).to eq(list_filter.all_count - 1)
      end
    end
  end

end
