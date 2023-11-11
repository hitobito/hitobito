# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Subscriber::FilterController, js: true do

  let(:list)  { mailing_lists(:leaders) }
  let(:group) { list.group }
  let!(:subscriber_id) { groups(:bottom_layer_one).id } # preload

  before do
    sign_in
  end

  it 'edit the language filter for mailing list' do 
    visit edit_group_mailing_list_filter_path(group.to_param, list.to_param)
    
    find('a.accordion-toggle.header[href="#languages"]').click

    check('filters_language_allowed_values_de')
    	
    all('form .btn-toolbar').first.click_button 'Speichern'

    expect(page).to have_content('Globale Bedingungen wurden erfolgreich aktualisiert')

    expect(find('#main')).to have_content('Sprache ist Deutsch')

    
  end

  it 'show the language filter for mailing list' do 
    mailing_list.update(filter_chain: { language: { allowed_values: [:de] }})

  end
end
