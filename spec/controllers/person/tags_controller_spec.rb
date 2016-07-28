# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

require 'spec_helper'

describe Person::TagsController do

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  before { sign_in(top_leader) }

  describe 'GET #query' do
    let(:group) { groups(:top_layer) }
    let(:top_leader) { people(:top_leader) }
    let(:bottom_member) { people(:bottom_member) }

    before do
      bottom_member.tags.create!(name: 'loremipsum')
      top_leader.tags.create!(name: 'lorem')
      top_leader.tags.create!(name: 'ipsum')
    end

    it 'returns empty array if no :q param is given' do
      get :query, group_id: group.id, person_id: bottom_member.id
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns empty array if no tag matches' do
      get :query, group_id: group.id, person_id: bottom_member.id, q: 'lipsum'
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns empty array if :q param is not at least 3 chars long' do
      get :query, group_id: group.id, person_id: bottom_member.id, q: 'or'
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns matching and unassigned tags if :q param at least 3 chars long' do
      get :query, group_id: group.id, person_id: bottom_member.id, q: 'ore'
      expect(JSON.parse(response.body)).to eq([{'label' => 'lorem'}])
    end
  end

  describe 'POST #create' do
    it 'creates person tag' do
      post :create, group_id: bottom_member.groups.first.id,
                    person_id: bottom_member.id,
                    tag: { name: 'lorem' }

      expect(bottom_member.tags.count).to eq(1)
      expect(assigns(:tag).name).to eq('lorem')
      is_expected.to redirect_to group_person_path(bottom_member.groups.first, bottom_member)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes person tag' do
      tag = bottom_member.tags.create!(name: 'lorem')
      delete :destroy, group_id: bottom_member.groups.first.id,
                       person_id: bottom_member.id,
                       id: tag.id

      expect(bottom_member.tags.count).to eq(0)
      is_expected.to redirect_to group_person_path(bottom_member.groups.first, bottom_member)
    end
  end

end
