# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Subscriber::GroupController, js: true do

  let(:list)  { mailing_lists(:leaders) }
  let(:group) { list.group }
  let!(:subscriber_id) { groups(:bottom_layer_one).id } # preload

  before do
    sign_in
    visit new_group_mailing_list_group_path(group.id, list.id)

    expect(find('#roles')).to have_no_selector('input[type=checkbox]')

    # trigger typeahead
    fill_in 'subscription_subscriber', with: 'Bottom'

    expect(find('.typeahead.dropdown-menu')).to have_content('Top > Bottom One')
    expect(find('.typeahead.dropdown-menu')).to have_content('Bottom One > Group 11')

    # select entry from typeahead
    sleep 0.1 # to avoid race condition in remote-typeahead
    find('.typeahead.dropdown-menu li a', text: 'Top > Bottom One').click
  end

  it 'selects group and loads roles' do
    obsolete_node_safe do
      expect(find('#subscription_subscriber_id', visible: false).value).to eq subscriber_id.to_s

      expect(find('#roles')).to have_selector('input[type=checkbox]', count: 8) # roles
      expect(find('#roles')).to have_selector('h4', count: 2) # layers

      # check role and submit
      check('subscription_role_types_group::bottomgroup::leader')

      all('form .btn-toolbar').first.click_button 'Speichern'

      expect(page).to have_content('Abonnent Bottom One wurde erfolgreich')
    end
  end

  context 'toggling roles' do
    it 'toggles roles when clicking layer' do
      obsolete_node_safe do
        is_expected.to have_selector('input[data-layer="Bottom Layer"]', count: 0)

        find('h4.filter-toggle', text: 'Bottom Layer').click
        expect(page).to have_css('input:checked', count: 7)

        find('h4.filter-toggle', text: 'Bottom Layer').click
        expect(page).to have_css('input:checked', count: 0)
      end
    end

    it 'toggles roles when clicking group' do
      obsolete_node_safe do
        is_expected.to have_selector('input[data-layer="Bottom Layer"]', count: 0)

        find('label.filter-toggle', text: 'Bottom Group').click
        expect(page).to have_css('input:checked', count: 2)

        find('label.filter-toggle', text: 'Bottom Group').click
        expect(page).to have_css('input:checked', count: 0)
      end
    end
  end

  context 'assign tags' do
    let! (:email_primary_invalid) { PersonTags::Validation.email_primary_invalid(create: true) } 
    let! (:email_additional_invalid) { PersonTags::Validation.email_additional_invalid(create: true) } 

    it 'assigns multiple included tags' do
      obsolete_node_safe do
        collection_select = find('#subscription_included_subscription_tags_ids_chosen .chosen-choices') 

        expect(collection_select).to have_no_selector('li.search-choice')

        collection_select.fill_in(with: 'Mail')

        find('.chosen-drop li.active-result', text: 'Haupt-E-Mail ungültig').click

        collection_select.fill_in(with: 'Mail')

        find('.chosen-drop li.active-result', text: 'Weitere E-Mail ungültig').click

        expect(collection_select).to have_selector('li.search-choice', count: 2)

        all('form .btn-toolbar').first.click_button 'Speichern'
        expect(page).to have_content('Abonnent Bottom One wurde erfolgreich')

        expect(page).to have_content('Nur Personen mit:')
        is_expected.to have_selector('span.person-tag', text: 'Haupt-E-Mail ungültig')
        is_expected.to have_selector('span.person-tag', text: 'Weitere E-Mail ungültig')
      end
    end

    it 'assigns multiple excluded tags' do
      obsolete_node_safe do
        collection_select = find('#subscription_excluded_subscription_tags_ids_chosen .chosen-choices') 

        expect(collection_select).to have_no_selector('li.search-choice')

        collection_select.fill_in(with: 'Mail')

        find('.chosen-drop li.active-result', text: 'Haupt-E-Mail ungültig').click

        collection_select.fill_in(with: 'Mail')

        find('.chosen-drop li.active-result', text: 'Weitere E-Mail ungültig').click

        expect(collection_select).to have_selector('li.search-choice', count: 2)

        all('form .btn-toolbar').first.click_button 'Speichern'
        expect(page).to have_content('Abonnent Bottom One wurde erfolgreich')

        expect(page).to have_content('Personen ausschliessen mit:')
        is_expected.to have_selector('span.person-tag', text: 'Haupt-E-Mail ungültig')
        is_expected.to have_selector('span.person-tag', text: 'Weitere E-Mail ungültig')
      end
    end

    it 'assigns same tag as excluded and included' do
      obsolete_node_safe do
        excluded_collection_select = find('#subscription_excluded_subscription_tags_ids_chosen .chosen-choices') 

        expect(excluded_collection_select).to have_no_selector('li.search-choice')

        excluded_collection_select.fill_in(with: 'Mail')

        find('.chosen-drop li.active-result', text: 'Haupt-E-Mail ungültig').click

        expect(excluded_collection_select).to have_selector('li.search-choice', count: 2)

        included_collection_select = find('#subscription_included_subscription_tags_ids_chosen .chosen-choices') 

        expect(included_collection_select).to have_no_selector('li.search-choice')

        included_collection_select.fill_in(with: 'Mail')

        find('.chosen-drop li.active-result', text: 'Haupt-E-Mail ungültig').click

        expect(included_collection_select).to have_selector('li.search-choice', count: 2)

        all('form .btn-toolbar').first.click_button 'Speichern'
        expect(page).to have_content('Abonnent Bottom One wurde erfolgreich')

        expect(page).to have_content('Personen ausschliessen mit:')
        expect(page).to have_content('Nur Personen mit:')
        is_expected.to have_selector('span.person-tag', text: 'Haupt-E-Mail ungültig', count: 2)
        is_expected.to have_selector('span.person-tag', text: 'Weitere E-Mail ungültig', count: 2)
      end
    end
  end
end
