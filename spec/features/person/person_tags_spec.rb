# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
    context 'user without :index_tags permission' do
      let(:user) { secretary }

      it 'does not show tags section' do
        expect(page).to have_no_content('Tags')
      end
    end

    context 'user with :index_tags permission' do
      let(:user) { leader }

      it 'lists tags without categories' do
        person.tag_list.add('lorem', 'ipsum')
        person.save!
        visit group_person_path(group_id: group.id, id: person.id)

        expect(page).to have_content('Tags')
        expect(all('.person-tags-category').length).to eq(1)
        expect(page).to have_no_selector('.person-tags-category-title')
        expect(all('.person-tag')[0].text).to eq('ipsum')
        expect(all('.person-tag')[1].text).to eq('lorem')
      end

      it 'lists tags grouped by categories' do
        person.tag_list.add('vegetable:potato', 'pizza', 'fruit:banana', 'fruit:apple')
        person.save!
        create_tag(person, PersonTags::Validation::EMAIL_PRIMARY_INVALID, 'no-email')
        visit group_person_path(group_id: group.id, id: person.id)

        expect(page).to have_content('Tags')
        expect(all('.person-tags-category').length).to eq(4)
        expect(all('.person-tags-category-title').map(&:text)).to eq(%w(fruit vegetable Validierung Andere))
        expect(all('.person-tags-category')[0].all('.person-tag').map(&:text)).
          to eq(%w(apple banana))
        expect(all('.person-tags-category')[1].all('.person-tag').map(&:text)).
          to eq(%w(potato))
        expect(all('.person-tags-category')[2].all('.person-tag').map(&:text)).
          to eq(['Haupt-E-Mail ungültig'])
        expect(all('.person-tags-category')[3].all('.person-tag').map(&:text)).
          to eq(%w(pizza))
      end
    end
  end

  context 'creation' do
    before do
      user.tag_list.add('pasta')
      user.save!
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
        fill_in 'acts_as_taggable_on_tag[name]', :with => 'pizza'
      end
      find('.person-tags-add-form button').click
      expect(page).to have_selector('.person-tag', text: 'pizza')
      person.reload
      expect(person.tags.count).to eq(1)
      expect(person.tag_list).to eq(['pizza'])
      expect(page).to have_selector('.person-tag-add')
      expect(page).to have_no_selector('.person-tags-add-form')

      find('.person-tag-add').click
      within '.person-tags-add-form' do
        fill_in 'acts_as_taggable_on_tag[name]', :with => 'pas'
      end
      expect(page).to have_selector('ul.typeahead li a', text: 'pasta')
      find('ul.typeahead li a').click
      find('.person-tags-add-form button').click
      expect(page).to have_selector('.person-tag', text: 'pasta')
      person.reload
      expect(person.tags.count).to eq(2)
      expect(Set.new(person.tag_list)).to eq(Set.new(['pizza', 'pasta']))

      find('.person-tag-add').click
      within '.person-tags-add-form' do
        fill_in 'acts_as_taggable_on_tag[name]', :with => 'fruit:banana'
      end
      find('.person-tags-add-form button').click
      expect(page).to have_selector('.person-tags-category', count: 2)
      expect(all('.person-tags-category-title').map(&:text)).to eq(%w(fruit Andere))
      expect(all('.person-tags-category')[0].all('.person-tag').map(&:text)).
        to eq(%w(banana))
      expect(all('.person-tags-category')[1].all('.person-tag').map(&:text)).
        to eq(%w(pasta pizza))
      person.reload
      expect(person.tags.count).to eq(3)
      expect(Set.new(person.tag_list)).to eq(Set.new(['pizza', 'pasta', 'fruit:banana']))
    end
  end

  context 'deletion' do
    before do
      person.tag_list.add('pizza', 'fruit:banana', 'fruit:apple')
      person.save!
      visit group_person_path(group_id: group.id, id: person.id)
    end

    it 'removes deleted tags' do
      expect(page).to have_selector('.person-tags-category', count: 2)
      expect(page).to have_selector('.person-tag-remove', count: 3)

      find('.person-tag', text: 'apple').find('.person-tag-remove').click
      expect(page).to have_selector('.person-tags-category', count: 2)
      expect(all('.person-tags-category')[0].all('.person-tag').map(&:text)).
        to eq(%w(banana))

      find('.person-tag', text: 'banana').find('.person-tag-remove').click
      expect(page).to have_selector('.person-tags-category', count: 1)
      expect(all('.person-tags-category')[0].all('.person-tag').map(&:text)).
        to eq(%w(pizza))
    end
  end

  private

  def create_tag(person, name, tooltip)
    ActsAsTaggableOn::Tagging.create!(
      taggable: person,
      hitobito_tooltip: tooltip,
      tag: ActsAsTaggableOn::Tag.find_or_create_by(name: name),
      context: 'tags'
    )
  end

end
