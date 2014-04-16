# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'Person Autocomplete', js: true do

  subject { page }
  let(:group) { groups(:top_group) }

  it 'knows about visibility of dropdown menu' do
    obsolete_node_safe do
      sign_in
      visit root_path
      page.should have_content('TopGroup')
      page.should have_content('Personen')
      click_link 'Personen'
      should have_content ' Person hinzufügen'
      click_link 'Person hinzufügen'
      should have_content 'Person hinzufügen'
    end
  end

  context 'highlights content in typeahead' do
    it 'for regular queries' do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group)

        fill_in 'Person', with: 'gibberish'
        page.should_not have_selector('.typeahead.dropdown-menu')

        fill_in 'Person', with: 'Top'
        page.should have_selector('.typeahead.dropdown-menu li', text: 'Top Leader')
        find('.typeahead.dropdown-menu li').should have_selector('strong', text: 'Top')
      end
    end

    it 'for two word queries' do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: { type: 'Group::TopGroup::Leader' })

        fill_in 'Person', with: 'Top Super'
        #sleep(0.5)
        page.should have_selector('.typeahead.dropdown-menu li', text: 'Top Leader')
        find('.typeahead.dropdown-menu li').should have_selector('strong', text: 'Top')
        find('.typeahead.dropdown-menu li').should have_selector('strong', text: 'Super')
      end
    end

    it 'for queries with weird spaces' do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: { type: 'Group::TopGroup::Leader' })

        fill_in 'Person', with: 'Top  Super '
        #sleep(0.5)
        page.should have_selector('.typeahead.dropdown-menu li', text: 'Top Leader')
        find('.typeahead.dropdown-menu li').should have_selector('strong', text: 'Top')
        find('.typeahead.dropdown-menu li').should have_selector('strong', text: 'Super')
      end
    end

    it 'saves content from typeahead' do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: { type: 'Group::TopGroup::Leader' })

        # search name only
        fill_in 'Person', with: 'Top'
        find('.typeahead.dropdown-menu li').should have_content 'Top Leader'
        find('.typeahead.dropdown-menu li').click

        all('form .btn-toolbar').first.click_button 'Speichern'
        should have_content 'Rolle Leader für Top Leader in TopGroup wurde erfolgreich erstellt.'
      end
    end

  end

end
