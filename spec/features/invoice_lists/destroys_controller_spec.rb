# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoiceLists::DestroysController, js: true do
  let(:layer) { groups(:top_layer) }

  let(:draft_invoices) do
    [0..10].map do
      Fabricate(:invoice, {
        due_at: 10.days.from_now,
        creator: people(:top_leader),
        state: :draft,
        recipient: people(:bottom_member),
        group: layer
      })
    end
  end

  let!(:invoice_list) do
    InvoiceList.create(title: 'membership fee', invoices: draft_invoices, group: layer)
  end

  let(:user) { people(:top_leader) }
  let(:table) { page.all('table')[0] }
  let(:modal) { page.find('#invoice-list-destroy') }
  let(:destroy_link) { table.find('td a[title="Löschen"]') }

  before { sign_in(user) }

  context 'for invoice list with only draft invoices' do
    it 'shows modal with confirm text' do
      visit group_invoice_lists_path(layer)

      expect(table).to have_content(/membership fee/)
      destroy_link.click
      expect(page).to have_text(/Wollen Sie die Sammelrechnung wirklich löschen?/)

      expect do
        modal.find('button[type="submit"]').click
        expect(page).to have_css('#flash .alert-success', text: "Sammelrechnung membership fee wurde erfolgreich gelöscht.")
      end.to change { InvoiceList.count }.by(-1)
    end
  end

  context 'for invoice list with not only draft invoices' do
    before { draft_invoices.sample.update!(state: :sent) }

    it 'shows modal with confirm text' do
      visit group_invoice_lists_path(layer)

      expect(table).to have_content(/membership fee/)
      destroy_link.click

      expect(page).to have_text(<<~TEXT.squish)
        In der Sammelrechnung ist mindesents eine Rechnung enthalten, welche weder den Status
        "Entwurf" noch "Storniert" hat. Daher kann die Sammelrechnung nicht gelöscht werden.
      TEXT

      expect(modal).to have_css('button[type="submit"][disabled="disabled"]')
    end
  end
end
