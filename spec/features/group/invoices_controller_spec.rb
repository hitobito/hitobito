# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoicesController do

  it 'shows invoices link when person is authorised' do
    sign_in(people(:bottom_member))
    visit root_path
    expect(page).to have_link 'Rechnungen'
  end

  it 'shows invoices subnav when person is authorised' do
    sign_in(people(:bottom_member))
    visit group_invoices_path(groups(:bottom_layer_one))
    expect(page).to have_link 'Rechnungen'
    expect(page).to have_css('nav.nav-left', text: 'Einstellungen')
  end

  it 'hides invoices link when person is authorised' do
    sign_in(people(:top_leader))
    visit root_path
    expect(page).not_to have_link 'Rechnungen'
  end

end

