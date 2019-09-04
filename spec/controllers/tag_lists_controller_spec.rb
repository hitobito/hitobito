#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe TagListsController do

  before { sign_in(people(:top_leader)) }

  let(:group)   { groups(:top_group) }
  let(:person1) { people(:top_leader) }
  let(:person2) { people(:bottom_member) }

  context 'authorization' do

    before do
      sign_in(people(:bottom_member))
    end

    it 'refuses to add a tag to a person we cannot manage' do
      person = people(:top_leader)
      post :create, group_id: group.id, ids: person.id, tags: 'Tagname'
      expect(flash[:notice]).to include 'Es wurden keine Tags erstellt'
      expect(person.reload.tags.count).to be 0
    end

    it 'refuses to remove a tag from a person we cannot manage' do
      person = people(:top_leader)
      person.tag_list.add('remove?')
      expect(person.save).to be_truthy
      tags_before = person.tags
      post :destroy, group_id: group.id, ids: people(:top_leader).id, tags: 'remove?'
      expect(flash[:notice]).to include 'Es wurden keine Tags entfernt'
      expect(person.reload.tags).to eq tags_before
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
    it 'creates only one tag for one person' do
      expect do
        post :create, group_id: group, ids: person1.id, tags: 'new tag'
      end.to change { Person.tags.count }.by(1)

      expect(flash[:notice]).to include 'Ein Tag wurde erstellt'
    end

    it 'does nothing if the tag already exists' do
      person = people(:top_leader)
      person.tag_list.add('existing')
      person.save!
      expect do
        post :create, group_id: group, ids: person.id, tags: 'existing'
      end.not_to(change { Person.tags.count })

      expect(flash[:notice]).to include 'Es wurden keine Tags erstellt'
    end

    it 'may create the same tag on multiple people' do
      expect do
        post :create, group_id: group, ids: [person1.id, person2.id].join(','), tags: 'same tag multiple people'
      end.to change { Person.tags.count }.by(1)

      expect(flash[:notice]).to include '2 Tags wurden erstellt'

      expect(person1.tags.collect(&:name)).to include 'same tag multiple people'
      expect(person2.tags.collect(&:name)).to include 'same tag multiple people'
    end

    it 'may create multiple tags for one person' do
      expect do
        post :create, group_id: group, ids: person1.id, tags: 'new tag 2, another, one more'
      end.to change { Person.tags.count }.by(3)

      expect(flash[:notice]).to include '3 Tags wurden erstellt'
    end

    it 'may create multiple tags on multiple people' do
      expect do
        post :create, group_id: group, ids: [person1.id, person2.id].join(','), tags: 't3, t4'
      end.to change { Person.tags.count }.by(2)

      expect(flash[:notice]).to include '4 Tags wurden erstellt'
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
      tag_test  = ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name('test')[0]
      tag_once  = ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name('once')[0]
      tag_twice = ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name('twice')[0]
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
    it 'deletes only one tag from one person' do
      person1.tag_list.add('remove me')
      person1.save!
      expect do
        delete :destroy, group_id: group, ids: person1.id, tags: {'remove me' => 'on'}
      end.to change { Person.tags.count }.by(-1)

      expect(flash[:notice]).to include 'Ein Tag wurde entfernt'
    end

    it 'does nothing if the tag does not exist' do
      expect do
        delete :destroy, group_id: group, ids: person1.id, tags: 'existing'
      end.to change { Person.tags.count }.by(0)

      expect(flash[:notice]).to include 'Es wurden keine Tags entfernt'
    end

    it 'may delete the same tag from multiple people' do
      tag_name = 'remove me too'
      person1.tag_list.add(tag_name)
      person1.save!
      person2.tag_list.add(tag_name)
      person2.save!
      expect do
        delete :destroy, group_id: group, ids: [person1.id, person2.id].join(','), tags: {tag_name => 'on'}
      end.to change { Person.tags.count }.by(-1)

      expect(flash[:notice]).to include '2 Tags wurden entfernt'
    end

    it 'may delete multiple tags from one person' do
      person1.tag_list.add(['tag 1', 'tag 2', 'tag 3'])
      person1.save!
      expect do
        delete :destroy, group_id: group, ids: person1.id, tags: {'tag 2' => 'on', 'tag 1' => 'on', 'tag 3' => 'on'}
      end.to change { Person.tags.count }.by(-3)

      expect(flash[:notice]).to include '3 Tags wurden entfernt'
    end

    it 'may delete multiple tags from multiple people' do
      person1.tag_list.add(['t3', 't4'])
      person1.save!
      person2.tag_list.add(['t3', 't4'])
      person2.save!
      expect do
        delete :destroy, group_id: group, ids: [person1.id, person2.id].join(','), tags: {t3: 'on', t4: 'on'}
      end.to change { Person.tags.count }.by(-2)

      expect(flash[:notice]).to include '4 Tags wurden entfernt'
    end
  end

end
