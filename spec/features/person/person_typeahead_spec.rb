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
    skip "Expected to find text 'Person hinzufügen'"
    obsolete_node_safe do
      sign_in
      visit root_path
      expect(page).to have_content('TopGroup')
      expect(page).to have_content('Personen')
      click_link 'Personen'
      is_expected.to have_content ' Person hinzufügen'
      click_link 'Person hinzufügen'
      is_expected.to have_content 'Person hinzufügen'
    end
  end

  context 'highlights content in typeahead' do
    it 'for non-existing queries' do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group)
        fill_in 'Person', with: 'gcxy'
        expect(page).to have_no_selector('ul[role="listbox"]')
      end
    end

    it 'for regular queries' do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group)

        fill_in 'Person', with: 'Top'
        expect(page).to have_selector('ul[role="listbox"] li[role="option"]', text: 'Top Leader')
        expect(find('ul[role="listbox"] li[role="option"]')).to have_selector('mark', text: 'Top')
      end
    end

    it 'for queries with /' do
      people(:top_leader).update!(first_name: 'Top /')
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group)

        fill_in 'Person', with: 'Top /'
        expect(page).to have_selector('ul[role="listbox"] li[role="option"]', text: 'Top / Leader')
        expect(find('ul[role="listbox"] li[role="option"]')).to have_selector('mark', text: 'Top /')
      end
    end

    it 'saves content from autocomplete' do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: { type: 'Group::TopGroup::Leader' })

        # search name only
        fill_in 'Person', with: 'Top'
        expect(find('ul[role="listbox"] li[role="option"]')).to have_content 'Top Leader'
        find('ul[role="listbox"] li[role="option"]').click

        all('form .btn-group').first.click_button 'Speichern'
        is_expected.to have_content 'Rolle Leader für Top Leader in TopGroup wurde erfolgreich erstellt.'
      end
    end

  end

end
