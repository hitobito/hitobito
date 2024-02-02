# frozen_string_literal: true

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'


describe MailingListsController, js: true do

  let(:user) { people(:top_leader) }
  let(:list) { mailing_lists(:leaders) }

  before { sign_in(user) }

  context 'index' do
    before { visit group_mailing_lists_path(list.group) }
    subject(:list_row) { find('tr', id: "mailing_list_#{list.id}") }

    context 'as user who may show list' do
      let(:user) { people(:top_leader) }

      it 'renders list name as link if current_user can show' do
        expect(list_row).to have_selector 'td strong a', text: list.name
      end
    end
  end

  it 'removes two labels from existing mailing' do
    list.update(preferred_labels: %w(Mutter Vater))
    visit edit_group_mailing_list_path(list.group, list)
    click_link('Mailing-Liste (E-Mail)')
    all('span.chip a')[0].click
    expect(page).to have_link 'Mailing-Liste (E-Mail)', class: 'active'
    expect(page).not_to have_content 'Mutter'
    click_button 'Speichern'

    expect(page).not_to have_content 'Mutter'
    expect(page).to have_content 'Vater'

    visit edit_group_mailing_list_path(list.group, list)
    click_link('Mailing-Liste (E-Mail)')
    all('span.chip a')[0].click
    click_button 'Speichern'

    expect(page).not_to have_content 'Vater'
  end

  it 'adds single label to new mailing list' do
    visit new_group_mailing_list_path(list.group)
    fill_in 'Name', with: 'test'
    click_link('Mailing-Liste (E-Mail)')
    fill_in 'Mailinglisten Adresse', with: 'test'
    find('.chip-add').click
    fill_in id: 'label', with: 'Vater'
    page.find('body').click # blur
    expect(page).to have_content 'Vater'

    click_button 'Speichern'
    expect(page).to have_content 'Vater'
  end

  it 'adds two preferred_labels to existing mailing list' do
    visit edit_group_mailing_list_path(list.group, list)
    click_link('Mailing-Liste (E-Mail)')
    find('.chip-add').click
    fill_in id: 'label', with: 'Vater'
    page.find('body').click # blur
    expect(page).to have_content 'Vater'

    find('.chip-add').click
    fill_in id: 'label', with: 'Mutter'
    page.find('body').click # blur
    expect(page).to have_content 'Mutter'

    click_button 'Speichern'

    expect(page).to have_content 'Mutter, Vater'
  end

  describe 'configurable list', :js do
    it 'can set opt_out on new list' do
      visit new_group_mailing_list_path(list.group)
      expect(page).to have_field 'Niemand', checked: true
      expect(page).not_to have_text 'Personen sind standardmässig'
      choose 'Nur konfigurierte Abonnenten'
      expect(page).to have_text 'Personen sind standardmässig'
      choose 'Abgemeldet (opt-in)'
      fill_in 'Name', with: 'test'
      click_button 'Speichern'
      expect(page).to have_content 'Abonnenten müssen sich selbst an/abmelden'
      click_link 'Abonnenten'
      expect(page).to have_css '.alert.alert-info', text: 'Nur die hier konfigurierten Personen ' \
        'dürfen sich selbst an-/abmelden und sind standardmässig ab-gemeldet.'
    end

    it 'can set opt_in on existing list' do
      visit edit_group_mailing_list_path(list.group, list)
      expect(page).to have_field 'Alle', checked: true
      expect(page).to have_field 'Angemeldet (opt-out)', checked: true
      expect(page).to have_text 'Personen sind standardmässig'
      choose 'Nur konfigurierte Abonnenten'
      choose 'Angemeldet (opt-out)'
      click_button 'Speichern'
      expect(page).to have_content 'Abonnenten dürfen sich selbst an/abmelden'
      click_link 'Abonnenten'
      expect(page).to have_css '.alert.alert-info', text: 'Nur die hier konfigurierten Personen ' \
        'dürfen sich selbst an-/abmelden und sind standardmässig an-gemeldet.'
    end
  end
end
