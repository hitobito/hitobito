# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

require 'spec_helper'

describe 'Person Tags', js: true do

  subject { page }
  let(:group) { groups(:top_group) }
  let(:leader) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: group).person }
  let(:secretary) { Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: group).person }
  let(:user) { leader }
  let(:person) { people(:top_leader) }

  before do
    sign_in(user)
  end

  context 'listing' do
    before do
      person.tags.create!(name: 'lorem')
      person.tags.create!(name: 'ipsum')
      visit group_person_path(group_id: group.id, id: person.id)
    end

    context 'user without :index_tags permission' do
      let(:user) { secretary }

      it 'does not show tags section' do
        expect(page).to have_no_content('Tags')
      end
    end

    context 'user with :index_tags permission' do
      let(:user) { leader }

      it 'lists tags' do
        expect(page).to have_content('Tags')
        expect(all('.person-tag')[0].text).to eq('lorem')
        expect(all('.person-tag')[1].text).to eq('ipsum')
      end
    end
  end

  context 'creation' do
    before do
      user.tags.create!(name: 'ipsum')
      visit group_person_path(group_id: group.id, id: person.id)
    end

    it 'adds newly created tags' do
      expect(page).to have_content('Tags')
      expect(page).to have_selector('.person-tag-add')
      expect(page).to have_no_selector('.person-tags-add-form')

      find('.person-tag-add').click
      expect(page).to have_no_selector('.person-tag-add')
      expect(page).to have_selector('.person-tags-add-form')

      within '.person-tags-add-form' do
        fill_in 'tag_name', :with => 'lorem'
      end
      find('.person-tags-add-form button').click
      expect(page).to have_selector('.person-tag', text: 'lorem')
      expect(person.tags.count).to eq(1)
      expect(person.tags.last.name).to eq('lorem')
      expect(page).to have_selector('.person-tag-add')
      expect(page).to have_no_selector('.person-tags-add-form')

      find('.person-tag-add').click
      within '.person-tags-add-form' do
        fill_in 'tag_name', :with => 'ips'
      end
      expect(page).to have_selector('ul.typeahead li a', text: 'ipsum')
      find('ul.typeahead li a').click
      find('.person-tags-add-form button').click
      expect(page).to have_selector('.person-tag', text: 'lorem')
      expect(person.tags.count).to eq(2)
      expect(person.tags.last.name).to eq('ipsum')
    end
  end

  context 'deletion' do
    before do
      person.tags.create!(name: 'lorem')
      person.tags.create!(name: 'ipsum')
      visit group_person_path(group_id: group.id, id: person.id)
    end

    it 'removes deleted tags' do
      expect(page).to have_selector('.person-tag', text: 'lorem')
      expect(page).to have_selector('.person-tag', text: 'ipsum')
      expect(page).to have_selector('.person-tag-remove')

      all('.person-tag-remove')[0].click
      expect(page).to have_no_selector('.person-tag', text: 'lorem')
      expect(page).to have_selector('.person-tag', text: 'ipsum')
    end
  end

end
