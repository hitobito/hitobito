# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoicesController do
  let(:group)   { groups(:bottom_layer_one) }
  let(:invoice) { invoices(:invoice) }

  it 'hides invoices link when person is not authorised' do
    top_group_member = Fabricate(Group::TopGroup::Member.sti_name, group: groups(:top_group))
    sign_in(top_group_member.person)
    visit root_path
    expect(page.find('#page-navigation')).not_to have_link 'Rechnungen'
  end

  context 'authenticated' do
    let(:person)  { people(:bottom_member) }

    before { sign_in(person) }

    it 'shows invoices link' do
      visit root_path
      expect(page.find('#page-navigation')).to have_link 'Rechnungen'
    end

    it 'shows invoices subnav' do
      visit group_invoices_path(group)
      expect(page).to have_link 'Rechnungen'
      expect(page).to have_css('nav.nav-left', text: 'Einstellungen')
    end

    it 'updating invoice_item updates total', js: true do
      skip 'unable to find Total inkl. MwSt. 1.00 CHF'
      visit group_people_path(group)
      click_link 'Rechnung erstellen'
      click_link 'Eintrag hinzufügen'
      fill_in 'Preis', with: 1
      expect(page).to have_content 'Total inkl. MwSt. 1.00 CHF'
    end

    it 'adding articles fills new invoice item', js: true do
      skip 'unable to find Total inkl. MwSt. 5.40 CHF'
      visit group_people_path(group)
      click_link 'Rechnung erstellen'
      select 'BEI-JU', from: 'invoice_item_article'
      expect(page).to have_content 'Total inkl. MwSt. 5.40 CHF'

      # TODO why does this part not execute success
      # expect(page).to have_content 'ermässiger Beitrage für Kinder und Jugendliche'
    end

    it 'creates payment reminder for multiple resources', js: true do
      Invoice.update_all(state: :issued, due_at: 1.day.ago)
      update_issued_at_to_current_year
      visit group_invoices_path(group)
      check 'all'
      click_link 'Rechnung stellen / mahnen'
      click_link 'Status setzen (Gestellt/Gemahnt)'
      expect(page).to have_content(/2 Rechnungen wurden gemahnt/)
    end

    it 'creates payment reminders', js: true do
      Invoice.update_all(state: :issued, due_at: 1.day.ago)
      visit group_invoice_path(group, invoice)
      click_link 'Rechnung stellen / mahnen'
      click_link 'Status setzen (Gestellt/Gemahnt)'
      expect(page).to have_content(/Rechnung \d+-\d+ wurde gemahnt/)
    end
  end

  context 'export single invoice' do
    before do
      sign_in(people(:bottom_member))
      visit group_invoice_path(group, invoice)
    end

    it 'dropdown is available' do
      expect(page).to have_link 'Export'
      expect(page).to have_link 'Rechnung inkl. Einzahlungsschein'
      expect(page).to have_link 'Rechnung separat'
      expect(page).to have_link 'Einzahlungsschein separat'
    end

    it 'exports full invoice' do
      click_link('Export')
      click_link('Rechnung inkl. Einzahlungsschein')
      expect(page).to have_current_path("/groups/#{group.id}/invoices/#{invoice.id}.pdf")
    end

    it 'exports only articles' do
      click_link('Export')
      click_link('Rechnung separat')
      expect(page).to have_current_path("/groups/#{group.id}/invoices/#{invoice.id}.pdf?payment_slip=false")
    end

    it 'exports only esr' do
      click_link('Export')
      click_link('Einzahlungsschein separat')
      expect(page).to have_current_path("/groups/#{group.id}/invoices/#{invoice.id}.pdf?articles=false")
    end
  end

  def update_issued_at_to_current_year
    sent = invoices(:sent)
    if sent.issued_at.year != Date.today.year
      sent.update(issued_at: Date.today.beginning_of_year)
    end
  end
end

