# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Subscriber::GroupController, js: true do

  let(:list)  { mailing_lists(:leaders) }
  let(:group) { list.group }

  it 'selects group and loads roles' do
    subscriber_id = groups(:bottom_layer_one).id # preload

    sign_in
    visit new_group_mailing_list_group_path(group.id, list.id)

    find('#roles').should_not have_selector('input[type=checkbox]')

    # trigger typeahead
    fill_in 'subscription_subscriber', with: 'Bottom'

    find('.typeahead.dropdown-menu').should have_content('Top > Bottom One')
    find('.typeahead.dropdown-menu').should have_content('Bottom One > Group 11')

    # select entry from typeahead
    find('.typeahead.dropdown-menu li a', text: 'Top > Bottom One').click

    page.should have_selector("input[value='#{subscriber_id}']")
    find('#subscription_subscriber_id').value.should == subscriber_id.to_s

    find('#roles').should have_selector('input[type=checkbox]', count: 7) # roles
    find('#roles').should have_selector('h5', count: 2) # layers

    # check role and submit
    check('subscription_role_types_group::bottomgroup::leader')

    all('form .btn-toolbar').first.click_button 'Speichern'

    page.should have_content('Abonnent Bottom One (Leader Bottom Group) wurde erfolgreich')
  end
end
