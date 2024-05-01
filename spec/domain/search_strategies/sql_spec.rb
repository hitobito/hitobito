#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe SearchStrategies::Sql do

  before do
    Rails.cache.clear
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

  describe '#list_people' do

    context 'as admin' do
      let(:user) { people(:top_leader) }

      it 'finds accessible person' do
        result = strategy(@bg_leader.last_name[1..5]).list_people

        expect(result).to include(@bg_leader)
      end

      it 'finds accessible person with two terms' do
        result = strategy("#{@bg_leader.last_name[1..5]} #{@bg_leader.first_name[0..3]}").list_people

        expect(result).to include(@bg_leader)
      end

      it 'does not find not accessible person' do
        result = strategy(@bg_member.last_name[1..5]).list_people

        expect(result).not_to include(@bg_member)
      end

      it 'does not search for too short queries' do
        result = strategy('e').list_people

        expect(result).to eq([])
      end

      it 'finds people without any roles' do
        result = strategy(@no_role.last_name[1..5]).list_people

        expect(result).to include(@no_role)
      end

      it 'does not find people not accessible person with deleted role' do
        result = strategy(@bg_member_with_deleted.last_name[1..5]).list_people

        expect(result).not_to include(@bg_member_with_deleted)
      end

      it 'finds deleted people' do
        result = strategy(@deleted_leader.last_name[1..5]).list_people

        expect(result).to include(@deleted_leader)
      end

      it 'finds deleted, not accessible people' do
        result = strategy(@deleted_bg_member.last_name[1..5]).list_people

        expect(result).to include(@deleted_bg_member)
      end

      context 'without any params' do
        it 'returns nothing' do
          result = strategy.list_people

          expect(result).to eq([])
        end
      end
    end

    context 'as leader' do
      let(:user) { @bl_leader }

      it 'finds accessible person' do
        result = strategy(@bg_leader.last_name[1..5]).list_people

        expect(result).to include(@bg_leader)
      end

      it 'finds local accessible person' do
        result = strategy(@bg_member.last_name[1..5]).list_people

        expect(result).to include(@bg_member)
      end

      it 'does not find people without any roles' do
        result = strategy(@no_role.last_name[1..5]).list_people

        expect(result).not_to include(@no_role)
      end

      it 'finds deleted people' do
        result = strategy(@deleted_leader.last_name[1..5]).list_people

        expect(result).to include(@deleted_leader)
      end
    end

    context 'as member' do
      let(:user) { @bg_member }

      it 'does not find deleted people' do
        result = strategy(@deleted_leader.last_name[1..5]).list_people

        expect(result).to_not include(@deleted_leader)
      end
    end

    context 'as root' do
      let(:user) { people(:root) }

      it 'finds every person' do
        result = strategy(@bg_member.last_name[1..5]).list_people

        expect(result).to include(@bg_member)
      end
    end

  end

  describe '#query_people' do

    context 'as leader' do
      let(:user) { people(:top_leader) }

      it 'finds accessible person' do
        result = strategy(@bg_leader.last_name[1..5]).query_people

        expect(result).to include(@bg_leader)
      end

      it 'does not find not accessible person' do
        result = strategy(@bg_member.last_name[1..5]).query_people

        expect(result).not_to include(@bg_member)
      end

      context 'without any params' do
        it 'returns nothing' do
          result = strategy.query_people

          expect(result).to eq(Person.none)
        end
      end
    end

    context 'as unprivileged person' do
      let(:user) { Fabricate(:person) }

      it 'finds zero people' do
        result = strategy(@bg_member.last_name[1..5]).query_people

        expect(result.to_a).to eq(Person.none.to_a)
      end
    end

  end

  describe '#query_groups' do

    context 'as leader' do
      let(:user) { people(:top_leader) }

      it 'finds groups' do
        result = strategy(groups(:bottom_layer_one).to_s[1..5]).query_groups

        expect(result).to include(groups(:bottom_layer_one))
      end

      context 'without any params' do
        it 'returns nothing' do
          result = strategy.query_groups

          expect(result).to eq([])
        end
      end
    end

    context 'as unprivileged person' do
      let(:user) { Fabricate(:person) }

      it 'finds groups' do
        result = strategy(groups(:bottom_layer_one).to_s[1..5]).query_groups

        expect(result).to include(groups(:bottom_layer_one))
      end
    end

  end

  describe '#query_events' do

    context 'as leader' do
      let(:user) { people(:top_leader) }

      it 'finds events' do
        result = strategy(events(:top_course).to_s[1..5]).query_events

        expect(result).to include(events(:top_course))
      end

      context 'without any params' do
        it 'returns nothing' do
          result = strategy.query_events

          expect(result).to eq([])
        end
      end
    end

    context 'as unprivileged person' do
      let(:user) { Fabricate(:person) }

      it 'finds events' do
        result = strategy(events(:top_course).to_s[1..5]).query_events

        expect(result).to include(events(:top_course))
      end
    end

  end

  describe '#query addresses' do

    let(:user) { Fabricate(:person) }

    it 'for the addresses' do
      [
        {
          :address => addresses(:stossstrasse_bern),
          :search_terms => ['stos', 'stosss', 'stoss bern']
        },
        {
          :address => addresses(:bahnhofstrasse_erlenbach),
          :search_terms => ['bah', 'hofst', 'bahn erlenbach']
        },
        {
          :address => addresses(:seestrasse_erlenbach),
          :search_terms => ['see', 'seestrasse', 'seestrasse erlenbach', 'erlenbach']
        },
        {
          :address => addresses(:rennweg_zuerich),
          :search_terms => ['renn','rennweg', 'rennweg zürich', 'zürich']
        },
        {
          :address => addresses(:dorfstrasse_teufen),
          :search_terms => ['dorf', 'dorfstrasse', 'dorfstrasse teufen', 'teufen']
        },
        {
          :address => addresses(:fallenstettenweg_reutlingen),
          :search_terms => ['fall', 'stetten', 'fallenstettenweg', 'fallenstettenweg reutlingen', 'reutlingen']
        },
        {
          :address => addresses(:wiesendangerstrasse_stadel),
          :search_terms => ['wiesen', 'dange', 'wiesendangerstrasse', 'wiesendangerstrasse stadel', 'stadel']
        },
        {
          :address => addresses(:spitzweg_winterthur),
          :search_terms => ['spitz', 'spitzweg', 'spitzweg winterthur', 'winterthur']
        }
      ].each do |address|
          address[:search_terms].each do |term|
            result = strategy(term).query_addresses

            expect(result).to include(address[:address]), "'#{address[:address]}' should be found with '#{term}'"
          end
        end
    end
  end

  def strategy(term = nil, page = nil)
    SearchStrategies::Sql.new(user, term, page)
  end

end
