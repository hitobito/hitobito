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

    expect(find('#roles')).not_to have_selector('input[type=checkbox]')

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

      expect(page).to have_content('Abonnent Bottom One (Leader Bottom Group) wurde erfolgreich')
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

end
