#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe SearchStrategies::PersonSearch do

  before do
    @tg_member = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
    @tg_extern = Fabricate(Role::External.name.to_sym, group: groups(:top_group)).person

    @bl_leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
    @bl_extern = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one)).person

    @bg_leader = Fabricate(Group::BottomGroup::Leader.name.to_sym,
                           group: groups(:bottom_group_one_one),
                           person: Fabricate(:person, last_name: 'Schurter', first_name: 'Franz')).person
    @bg_member = Fabricate(Group::BottomGroup::Member.name.to_sym,
                           group: groups(:bottom_group_one_one),
                           person: Fabricate(:person, last_name: 'Bindella', first_name: 'Yasmine')).person

    @bg_member_with_deleted = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
    leader = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one), person: @bg_member_with_deleted)
    leader.update(created_at: Time.now - 1.year)
    leader.destroy!

    @no_role = Fabricate(:person)

    role = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
    role.update(created_at: Time.now - 1.year)
    role.destroy
    @deleted_leader = role.person

    role = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
    role.update(created_at: Time.now - 1.year)
    role.destroy
    @deleted_bg_member = role.person

    # make sure names are long enough
    [@tg_member, @tg_extern, @bl_leader, @bl_extern, @bg_leader, @bg_member,
     @bg_member_with_deleted, @no_role, @deleted_leader, @deleted_bg_member].each do |p|
      p.update_columns(last_name: p.last_name * 3, first_name: p.first_name * 3)
    end
  end

  describe '#search_fulltext' do

    context 'as admin' do
      let(:user) { people(:top_leader) }

      it 'finds accessible person' do
        result = search_class(@bg_leader.last_name[0..5]).search_fulltext

        expect(result).to include(@bg_leader)
      end

      it 'finds accessible person with two terms' do
        result = search_class("#{@bg_leader.last_name[0..5]} #{@bg_leader.first_name[0..3]}").search_fulltext

        expect(result).to include(@bg_leader)
      end

      # infix search wasn't implemented
      xit 'finds accessible person with Infix term' do
        result = search_class(@bg_leader.last_name[1..5]).search_fulltext

        expect(result).to include(@bg_leader)
      end

      it 'does not find not accessible person' do
        result = search_class(@bg_member.last_name[0..5]).search_fulltext

        expect(result).not_to include(@bg_member)
      end

      it 'does not search for too short queries' do
        result = search_class('e').search_fulltext

        expect(result).to eq([])
      end

      it 'finds people without any roles' do
        result = search_class(@no_role.last_name[0..5]).search_fulltext

        expect(result).to include(@no_role)
      end

      it 'does not find people not accessible person with deleted role' do
        result = search_class(@bg_member_with_deleted.last_name[0..5]).search_fulltext

        expect(result).not_to include(@bg_member_with_deleted)
      end

      # flacky
      xit 'finds deleted people' do
        result = search_class(@deleted_leader.last_name[0..5]).search_fulltext

        expect(result).to include(@deleted_leader)
      end

      # flacky
      xit 'finds deleted, not accessible people' do
        result = search_class(@deleted_bg_member.last_name[0..5]).search_fulltext

        expect(result).to include(@deleted_bg_member)
      end
    end

    context 'as leader' do
      let(:user) { @bl_leader }

      it 'finds accessible person' do
        result = search_class(@bg_leader.last_name[0..5]).search_fulltext

        expect(result).to include(@bg_leader)
      end

      it 'finds local accessible person' do
        result = search_class(@bg_member.last_name[0..5]).search_fulltext

        expect(result).to include(@bg_member)
      end

      it 'does not find people without any roles' do
        result = search_class(@no_role.last_name[0..5]).search_fulltext

        expect(result).not_to include(@no_role)
      end

      it 'finds deleted people' do
        result = search_class(@deleted_leader.last_name[0..5]).search_fulltext

        expect(result).to include(@deleted_leader)
      end
    end

    context 'as member' do
      let(:user) { @bg_member }

      it 'does not find deleted people' do
        result = search_class(@deleted_leader.last_name[0..5]).search_fulltext

        expect(result).to_not include(@deleted_leader)
      end
    end

    context 'as root' do
      let(:user) { people(:root) }

      it 'finds every person' do
        result = search_class(@bg_member.last_name[0..5]).search_fulltext

        expect(result).to include(@bg_member)
      end
    end

  end

  def search_class(term = nil, page = nil)
    described_class.new(user, term, page)
  end

end
