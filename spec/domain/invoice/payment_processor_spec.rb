# frozen_string_literal: true

#  Copyright (c) 2022, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Invoice::PaymentProcessor do

  let(:invoice)        { invoices(:sent) }
  let(:invoice_config) { invoice.invoice_config }

  it 'parses 5 credit statements' do
    expect(parser.send(:credit_statements)).to have(5).items
  end

  it 'builds payments for each credit statement' do
    expect(parser.payments).to have(5).items
  end

  it 'first payment is assigned to an invoice' do
    invoice.update_columns(reference: '000000000000100000000000905')
    payment = parser.payments.first

    expect(parser.notice).to eq "Es wurde eine gültige Zahlung mit dazugehöriger Rechnung erkannt.\n" \
                                'Es wurden 4 gültige Zahlungen ohne dazugehörige Rechnungen erkannt.'
    expect(parser.alert).to be_nil
    expect(payment).to be_valid
  end

  it 'creates payments and marks invoice as payed' do
    invoice.update_columns(reference: '000000000000100000000000905',
                           total: 710.82)
    expect do
      expect(parser.process).to eq 5
    end.to change { Payment.count }.by(5)

    expect(parser.alert).to be_nil
    expect(parser.notice).to eq "Es wurde eine gültige Zahlung mit dazugehöriger Rechnung erkannt.\n" \
                                'Es wurden 4 gültige Zahlungen ohne dazugehörige Rechnungen erkannt.'
    expect(invoice.reload).to be_payed
  end

  it 'builds transaction identifier' do
    identifiers = parser.payments.map(&:transaction_identifier)

    expect(parser.alert).to be_nil
    expect(parser.notice).to eq 'Es wurden 5 gültige Zahlungen ohne dazugehörige Rechnungen erkannt.'

    expect(identifiers).to eq(
      ['20180314001221000006905084508206000000000000100000000000905710.822018-03-15 00:00:00 +0100CH6309000000250097798',
       '20180314001221000006915084508216000000000000100000000000800710.822018-03-15 00:00:00 +0100CH6309000000250097798',
       '20180314001221000006925084508226000000000000100000000001165710.822018-03-15 00:00:00 +0100CH6309000000250097798',
       '20180314001221000006935084508236000000000000100000000001069710.822018-03-15 00:00:00 +0100CH6309000000250097798',
       '20180314001221000006945084508246000000000000100000000000750710.822018-03-15 00:00:00 +0100CH6309000000250097798'])
  end

  it 'creates payment and marks invoice as payed and updates invoice_list' do
    list = InvoiceList.create!(title: :title, group: invoice.group)
    invoice.update_columns(reference: '000000000000100000000000905',
                           invoice_list_id: list.id,
                           total: 710.82)
    expect do
      expect(parser.process).to eq 5
    end.to change { Payment.count }.by(5)

    expect(parser.alert).to be_nil
    expect(parser.notice).to eq "Es wurde eine gültige Zahlung mit dazugehöriger Rechnung erkannt.\n" \
                                'Es wurden 4 gültige Zahlungen ohne dazugehörige Rechnungen erkannt.'

    expect(invoice.reload).to be_payed
    expect(list.reload.amount_paid.to_s).to eq '710.82'
    expect(list.reload.recipients_paid).to eq 1
  end

  it 'creates payment, saves transaction xml and payee' do
    list = InvoiceList.create!(title: :title, group: invoice.group)
    invoice.update_columns(reference: '000000000000100000000000905',
                           invoice_list_id: list.id,
                           total: 710.82)
    expect do
      expect(parser.process).to eq 5
    end.to change { Payment.count }.by(5)

    expect(parser.alert).to be_nil
    expect(parser.notice).to eq "Es wurde eine gültige Zahlung mit dazugehöriger Rechnung erkannt.\n" \
                                'Es wurden 4 gültige Zahlungen ohne dazugehörige Rechnungen erkannt.'

    payment = invoice.payments.first
    xml = payment.transaction_xml
    data = Hash.from_xml(xml)['TxDtls']
    expect(data['Refs']['AcctSvcrRef']).to eq('20180314001221000006905084508206')
    expect(data['Refs']['Prtry']['Ref']).to eq('20180314001221000006905')
    expect(data['Amt']).to eq('710.82')
    expect(data['RltdPties']['Dbtr']['Nm']).to eq('Maria Bernasconi')
    expect(data['RltdPties']['Dbtr']['PstlAdr']).to be_present

    expect(payment.payee.person).to eq(invoice.recipient)
    expect(payment.payee.person_name).to eq('Maria Bernasconi')
    expect(payment.payee.person_address).to eq('Place de la Gare 15, 2502 Biel/Bienne')
  end

  it 'uses ValDat as received_at' do
    received_ats = parser.payments.map(&:received_at)

    expect(received_ats).to all(eq(Date.new(2018, 3, 15)))
  end

  it 'creates payment and marks scor referenced invoice as payed' do
    invoice.update_columns(reference: Invoice::ScorReference.create('000000100000000000905'),
                           esr_number: '00 00000 00000 10000 00000 00905',
                           total: 710.82)
    expect do
      expect(parser.process).to eq 5
    end.to change { Payment.count }.by(5)
    expect(invoice.reload).to be_payed
  end


  it 'invalid payments only produce set alert' do
    parser = parser('camt.054-without-amount')
    expect(parser.alert).to eq 'Es wurde eine ungültige Zahlung erkannt.'
    expect(parser.notice).to be_nil
  end

  it 'creates valid payment although esr reference is not found' do
    parser = parser('camt.054-without-esr-reference')
    parser.process

    payments = parser.payments

    expect(payments.size).to eq(1)

    payment = payments.first

    expect(payment).to be_valid
    expect(parser.notice).to eq 'Es wurde eine gültige Zahlung ohne dazugehörige Rechnung erkannt.'
    expect(parser.alert).to be_nil
    expect(payment.reference).to be_nil
  end

  it 'invalid and valid payments set alert and notice' do
    invoice.update_columns(reference: '000000000000100000000000905')
    expect(parser.alert).to be_nil
    expect(parser.notice).to eq "Es wurde eine gültige Zahlung mit dazugehöriger Rechnung erkannt.\n" \
                                'Es wurden 4 gültige Zahlungen ohne dazugehörige Rechnungen erkannt.'
  end

  it 'falls back to more general dates if no payment date is included' do
    expect(parser('camt.054-without-payment-dates').payments.first.received_at)
      .to eq(Time.zone.parse('2022-01-26T00:00:00+01:00').to_date)
    expect(parser('camt.054-without-any-optional-dates').payments.first.received_at)
      .to eq(Time.zone.parse('2022-01-26T18:43:27+01:00').to_date)
  end

  private

  def parser(file = 'camt.054-ESR-ASR_T_CH0209000000857876452_378159670_0_2018031411011923')
    @parser ||= Invoice::PaymentProcessor.new(read(file))
  end

  def read(name)
    Rails.root.join("spec/fixtures/invoices/#{name}.xml").read
  end

end
