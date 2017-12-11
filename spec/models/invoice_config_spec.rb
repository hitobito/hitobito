# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoiceConfig do
  let(:group)          { groups(:top_layer) }
  let(:person)         { people(:top_leader) }
  let(:other_person)   { people(:bottom_member) }
  let(:invoice_config) { group.invoice_config }

  it 'validates correct iban format' do
    invoice_config.update(iban: 'wrong format')

    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).to include('IBAN ist nicht gültig')
  end

  it 'validates correct account_number format' do
    invoice_config.update(account_number: 'wrong format')

    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).to include('Kontonummer ist nicht gültig')
  end

  it 'validates presence of payment_for' do
    invoice_config.update(payment_for: '')

    expect(invoice_config).not_to be_valid
  end

  it 'validates wordwrap of payment_for if bank payment' do
    invoice_config.update(payment_for: "line1 \n line2 \n \line 3", payment_slip: 'ch_bes')

    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).
      to include('Einzahlung für darf höchstens 2 Zeilen enthalten')
  end
end
