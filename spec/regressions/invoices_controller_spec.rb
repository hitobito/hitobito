# encoding: utf-8

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoicesController, type: :controller do

  render_views

  let(:group) { groups(:bottom_layer_one) }
  let!(:sent)        { invoices(:sent) }
  let(:letter)       { messages(:with_invoice) }
  let(:invoice_list) { letter.create_invoice_list(title: 'test', group_id: group.id) }

  before { sign_in(people(:bottom_member)) }

  describe 'GET #show' do
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before do
      update_issued_at_to_current_year
      sent.update(invoice_list: invoice_list)
    end

    it 'shows separate export options when viewing invoice list invoices' do
      get :index, params: { group_id: group.id, invoice_list_id: invoice_list.id }
      options = dom.find_link('Drucken').all(:xpath, '..//ul//li')
      expect(options.count).to eq 3
      expect(options.first.text).to eq 'Rechnung inkl. Einzahlungsschein'
    end

    it 'shows single letter_with_invoice export option when viewing invoices from letter with invoice' do
      invoice_list.update(message: letter)
      get :index, params: { group_id: group.id, invoice_list_id: invoice_list.id }
      options = dom.find_link('Drucken').all(:xpath, '..//ul//li')
      expect(options.count).to eq 1
      expect(options.first.text).to eq 'Rechnungsbriefe'
    end
  end

  def update_issued_at_to_current_year
    sent = invoices(:sent)
    if sent.issued_at.year != Date.today.year
      sent.update(issued_at: Date.today.beginning_of_year)
    end
  end
end
