# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe :payment_process, js: true do

  subject { page }

  let(:top_layer) { groups(:top_layer) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  before do
    sign_in(top_leader)
    visit new_group_payment_process_path(top_layer)
  end

  it 'processes payments and finds invoice' do
    invoice = Fabricate(:invoice, group: groups(:top_layer), recipient: bottom_member)
    invoice.update!(reference: '000000000000100000000000905')

    attach_file 'payment_process[file]', file_fixture('../invoices/camt.054-ESR-ASR_T_CH0209000000857876452_378159670_0_2018031411011923.xml')

    expect do
      find('button.btn', text: 'Hochladen').click
    end.to_not change { Payment.count }

    expect(page).to have_content('Es wurde eine gültige Zahlung mit dazugehöriger Rechnung erkannt.')
    expect(page).to have_content('Es wurden 4 gültige Zahlungen ohne dazugehörige Rechnungen erkannt.')

    payments_with_invoice = find('#payments-with-invoice')
    expect(payments_with_invoice.find_all('tbody tr').size).to eq(1)
    row_values = payments_with_invoice.find_all('tbody tr td').map(&:text)
    expect(row_values).to match_array([
      '', # icon
      invoice.title,
      invoice.recipient.full_name,
      "Entwurf", # invoice type
      "00 00834 96356 70000 00000 00019", # invoice reference
      "0.00", # invoice amount_open
      "710.82", # payment amount
      "15.03.2018" # payment date
    ])

    payments_without_invoice = find('#payments-without-invoice')
    expect(payments_without_invoice.find_all('tbody tr').size).to eq(4)

    expect do
      find('button.btn', text: '5 Zahlungen importieren').click
      sleep 0.5
    end.to change { Payment.count }.by(5)

    expect(invoice.payments.count).to eq(1)
  end
end
