# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoicesController do

  it 'hides invoices link when person is not authorised' do
    top_group_member = Fabricate(Group::TopGroup::Member.sti_name, group: groups(:top_group))
    sign_in(top_group_member.person)
    visit root_path
    expect(page).not_to have_link 'Rechnungen'
  end

  context 'authenticated' do
    let(:person)  { people(:bottom_member) }
    let(:group)   { groups(:bottom_layer_one) }

    before { sign_in(person) }

    it 'shows invoices link' do
      visit root_path
      expect(page).to have_link 'Rechnungen'
    end

    it 'shows invoices subnav' do
      visit group_invoices_path(group)
      expect(page).to have_link 'Rechnungen'
      expect(page).to have_css('nav.nav-left', text: 'Einstellungen')
    end

    it 'creates payment reminders', js: true do
      invoice = invoices(:sent)
      visit group_invoice_path(group, invoice)
      expect(page).not_to have_css('#new_payment_reminder')
      click_link 'Mahnung erstellen'
      fill_in 'Fällig am', with: invoice.due_at + 2.weeks
      click_button 'Speichern'
      expect(page).to have_content(/Mahnung.*wurde erfolgreich erstellt/)
      expect(page).not_to have_css('#new_payment_reminder')
    end

  end


end

