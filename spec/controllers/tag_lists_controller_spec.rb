#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe TagListsController do

  before { sign_in(people(:top_leader)) }
  before { allow(controller).to receive(:tag_list).and_return(tag_list_double) }

  let(:tag_list_double) { double('tag_list') }
  let(:group) { groups(:top_group) }
  let(:person1) { people(:top_leader) }
  let(:person2) { people(:bottom_member) }

  context 'authorization' do

    before do
      sign_in(people(:bottom_member))
    end

    it 'refuses to add a tag to a person we cannot manage' do
      expect(tag_list_double).to receive(:add).and_return(0)
      person = people(:top_leader)
      expect do
        post :create, group_id: group.id, ids: person.id, tags: 'Tagname'
      end.not_to(change { person.reload.tags })
    end

    it 'refuses to remove a tag from a person we cannot manage' do
      expect(tag_list_double).to receive(:remove).and_return(0)
      person = people(:top_leader)
      person.tag_list.add('remove?')
      expect(person.save).to be_truthy
      expect do
        post :destroy, group_id: group.id, ids: people(:top_leader).id, tags: 'remove?'
      end.not_to(change { person.reload.tags })
    end
  end

  context 'GET modal for bulk creating tags' do
    it 'shows modal' do
      xhr :get, :new, group_id: group.id, ids: [person1.id, person2.id].join(','), format: :js
      expect(response).to have_http_status(:ok)
      is_expected.to render_template('tag_lists/new')
      expect(assigns(:people_ids)).to contain_exactly person1.id, person2.id
    end
  end

  context 'POST create' do
    it 'creates a tag and displays flash message' do
      expect(tag_list_double).to receive(:add).and_return(1)
      post :create, group_id: group, ids: person1.id, tags: 'new tag'
      expect(flash[:notice]).to include 'Ein Tag wurde erstellt'
    end

    it 'creates zero tags and displays flash message' do
      expect(tag_list_double).to receive(:add).and_return(0)
      post :create, group_id: group, ids: person1.id, tags: 'existing'
      expect(flash[:notice]).to include 'Es wurden keine Tags erstellt'
    end

    it 'creates many tags and displays flash message' do
      expect(tag_list_double).to receive(:add).and_return(17)
      post :create, group_id: group, ids: person1.id, tags: 'new tag'
      expect(flash[:notice]).to include '17 Tags wurden erstellt'
    end
  end

  context 'GET modal for bulk deleting tags' do
    it 'shows modal' do
      xhr :get, :deletable, group_id: group.id, ids: [person1.id, person2.id].join(','), format: :js
      expect(response).to have_http_status(:ok)
      is_expected.to render_template('tag_lists/deletable')
      expect(assigns(:people_ids)).to contain_exactly person1.id, person2.id
      expect(assigns(:existing_tags)).to be_empty
    end

    it 'shows modal with tags and correct count' do
      sign_in(people(:root))
      person = people(:top_leader)
      person.tag_list.add('test', 'once', 'twice')
      person.save!
      another_person = people(:root)
      another_person.tag_list.add('twice')
      another_person.save!
      unrelated_person = people(:bottom_member)
      unrelated_person.tag_list.add('once', 'another')
      unrelated_person.save!
      tag_test  = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('test')
      tag_once  = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('once')
      tag_twice = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('twice')
      xhr :get, :deletable, group_id: group.id, ids: [person.id, another_person.id].join(','),
                            format: :js
      expect(response).to have_http_status(:ok)
      is_expected.to render_template('tag_lists/deletable')
      expect(assigns(:people_ids)).to contain_exactly person.id, another_person.id
      expect(assigns(:existing_tags)).to contain_exactly([tag_test, 1],
                                                         [tag_once, 1],
                                                         [tag_twice, 2])
    end
  end

  context 'DELETE destroy' do
    it 'removes a tag and displays flash message' do
      expect(tag_list_double).to receive(:remove).and_return(1)
      post :destroy, group_id: group, ids: person1.id, tags: 'new tag'
      expect(flash[:notice]).to include 'Ein Tag wurde entfernt'
    end

    it 'removes zero tags and displays flash message' do
      expect(tag_list_double).to receive(:remove).and_return(0)
      post :destroy, group_id: group, ids: person1.id, tags: 'existing'
      expect(flash[:notice]).to include 'Es wurden keine Tags entfernt'
    end

    it 'removes many tags and displays flash message' do
      expect(tag_list_double).to receive(:remove).and_return(17)
      post :destroy, group_id: group, ids: person1.id, tags: 'new tag'
      expect(flash[:notice]).to include '17 Tags wurden entfernt'
    end
  end

end
