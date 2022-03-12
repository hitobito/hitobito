# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

require 'spec_helper'

describe Payments::EbicsImport do
  subject { described_class.new(config) }

  let(:invoice_files) {
    [read('camt.054-ESR-ASR_T_CH0209000000857876452_378159670_0_2018031411011923')]
  }
  let(:config) { payment_provider_configs(:postfinance) }
  let(:epics_client) { double(:epics_client) }
  let(:payment_provider) { PaymentProvider.new(config) }

  before do
    config.update(status: :registered)

    allow(PaymentProvider).to receive(:new).and_return(payment_provider)
    allow(payment_provider).to receive(:client).and_return(epics_client)
  end

  it 'returns empty array if payment provider config is not initialized' do
    config.update(status: :draft)

    expect(payment_provider).to_not receive(:HPB)
    expect(payment_provider).to_not receive(:Z54)

    expect do
      payments = subject.run

      expect(payments).to be_empty
    end.to_not change { Payment.count }
  end

  it 'does not save if invoice not in payment provider config layer' do
    expect(epics_client).to receive(:HPB)

    expect(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

    expect(payment_provider).to receive(:Z54).with(Time.zone.yesterday, Time.zone.today).and_return(invoice_files)

    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: people(:top_leader), recipient: people(:bottom_member), group: groups(:top_layer))
    list = InvoiceList.create(title: 'membership fee', invoices: [invoice])

    invoice.update(reference: '000000000000100000000000800')
    expect(list.amount_paid).to eq(0)
    expect do
      subject.run
    end.to_not change { Payment.count }
  end

  it 'creates payment' do
    expect(epics_client).to receive(:HPB)

    expect(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

    expect(payment_provider).to receive(:Z54).with(Time.zone.yesterday, Time.zone.today).and_return(invoice_files)

    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: people(:top_leader), recipient: people(:bottom_member), group: groups(:bottom_layer_one))

    list = InvoiceList.create(title: 'membership fee', invoices: [invoice])

    invoice.update(reference: '000000000000100000000000800')
    expect(list.amount_paid).to eq(0)
    expect do
      payments = subject.run

      expect(payments.size).to eq(1)

      payment = payments.first
      expect(payment.invoice).to eq(invoice)
      expect(payment.transaction_identifier).to eq("20180314001221000006915084508216")
      expect(list.reload.amount_paid.to_s).to eq('710.82')
    end.to change { Payment.count }.by(1)
  end

  it 'creates payment by scor reference' do
    expect(epics_client).to receive(:HPB)

    expect(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

    expect(payment_provider).to receive(:Z54).with(Time.zone.yesterday, Time.zone.today).and_return(invoice_files)

    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: people(:top_leader), recipient: people(:bottom_member), group: groups(:bottom_layer_one))

    list = InvoiceList.create(title: 'membership fee', invoices: [invoice])

    invoice.update(reference: Invoice::ScorReference.create('000000100000000000800'),
                   esr_number: '00 00000 00000 10000 00000 00800')
    expect(list.amount_paid).to eq(0)
    expect do
      payments = subject.run

      expect(payments.size).to eq(1)

      payment = payments.first
      expect(payment.invoice).to eq(invoice)
      expect(payment.transaction_identifier).to eq("20180314001221000006915084508216")
      expect(list.reload.amount_paid.to_s).to eq('710.82')
    end.to change { Payment.count }.by(1)
  end

  it 'does not save if invoice not found' do
    expect(epics_client).to receive(:HPB)

    expect(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

    expect(payment_provider).to receive(:Z54).with(Time.zone.yesterday, Time.zone.today).and_return(invoice_files)

    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: people(:top_leader), recipient: people(:bottom_member), group: groups(:bottom_layer_one))
    invoice.update!(reference: '404')

    expect do
      payments = subject.run

      expect(payments).to be_empty
    end.to_not change { Payment.count }
  end

  it 'returns empty array if no download data available' do
    expect(epics_client).to receive(:HPB)

    expect(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

    expect(payment_provider).to receive(:Z54).with(Time.zone.yesterday, Time.zone.today).and_raise(Epics::Error::BusinessError.new('090005'))

    expect(Invoice::PaymentProcessor).to_not receive(:new)

    expect do
      payments = subject.run

      expect(payments).to be_empty
    end.to_not change { Payment.count }
  end

  private

  def read(name)
    Rails.root.join("spec/fixtures/invoices/#{name}.xml").read
  end
end
