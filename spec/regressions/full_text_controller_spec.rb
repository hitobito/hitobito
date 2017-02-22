# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe FullTextController, :mysql, type: :controller do

  sphinx_environment(:people, :groups) do

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

      index_sphinx
    end

    describe 'GET index' do

      context 'as admin' do
        before { sign_in(people(:top_leader)) }

        it 'finds accessible person' do
          get :index, q: @bg_leader.last_name[1..5]

          expect(assigns(:people)).to include(@bg_leader)
        end

        it 'does not find not accessible person' do
          get :index, q: @bg_member.last_name[1..5]

          expect(assigns(:people)).not_to include(@bg_member)
        end

        it 'does not search for too short queries' do
          get :index, q: 'e'

          expect(assigns(:people)).to eq([])
        end

        it 'finds people without any roles' do
          get :index, q: @no_role.last_name[1..5]

          expect(assigns(:people)).to include(@no_role)
        end

        it 'does not find people not accessible person with deleted role' do
          get :index, q: @bg_member_with_deleted.last_name[1..5]

          expect(assigns(:people)).not_to include(@bg_member_with_deleted)
        end

        it 'finds deleted people' do
          get :index, q: @deleted_leader.last_name[1..5]

          expect(assigns(:people)).to include(@deleted_leader)
        end

        it 'finds deleted, not accessible people' do
          get :index, q: @deleted_bg_member.last_name[1..5]

          expect(assigns(:people)).to include(@deleted_bg_member)
        end


        context 'without any params' do
          it 'returns nothing' do
            get :index

            expect(@response).to be_ok
            expect(assigns(:people)).to eq([])
          end
        end
      end

      context 'as leader' do
        before { sign_in(@bl_leader) }

        it 'finds accessible person' do
          get :index, q: @bg_leader.last_name[1..5]

          expect(assigns(:people)).to include(@bg_leader)
        end

        it 'finds local accessible person' do
          get :index, q: @bg_member.last_name[1..5]

          expect(assigns(:people)).to include(@bg_member)
        end

        it 'does not find people without any roles' do
          get :index, q: @no_role.last_name[1..5]

          expect(assigns(:people)).not_to include(@no_role)
        end

        it 'does not find deleted people' do
          get :index, q: @deleted_leader.last_name[1..5]

          expect(assigns(:people)).not_to include(@deleted_leader)
        end
      end

      context 'as root' do
        before { sign_in(people(:root)) }

        it 'finds every person' do
          get :index, q: @bg_member.last_name[1..5]

          expect(assigns(:people)).to include(@bg_member)
        end
      end

    end

    describe 'GET query' do

      context 'as leader' do
        before { sign_in(people(:top_leader)) }

        it 'finds accessible person' do
          get :query, q: @bg_leader.last_name[1..5]

          expect(@response.body).to include(@bg_leader.full_name)
        end

        it 'does not find not accessible person' do
          get :query, q: @bg_member.last_name[1..5]

          expect(@response.body).not_to include(@bg_member.full_name)
        end

        it 'finds groups' do
          get :query, q: groups(:bottom_layer_one).to_s[1..5]

          expect(@response.body).to include(groups(:bottom_layer_one).to_s)
        end

        context 'without any params' do
          it 'returns nothing' do
            get :query

            expect(@response).to be_ok
            expect(JSON.parse(@response.body)).to eq([])
          end
        end
      end

      context 'as unprivileged person' do
        before do
          person = Fabricate(:person)
          sign_in(person)
        end

        it 'finds zero people' do
          get :query, q: @bg_member.last_name[1..5]

          expect(assigns(:people)).to be_nil
        end
      end
    end


  end

end
