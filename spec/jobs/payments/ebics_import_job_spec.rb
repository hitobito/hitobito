# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

require 'spec_helper'

describe Payments::EbicsImportJob do
  include ActiveJob::TestHelper

  let(:invoice_file) {
    read('camt.054-ESR-ASR_T_CH0209000000857876452_378159670_0_2018031411011923')
  }
  let(:config) { payment_provider_configs(:postfinance) }
  let(:epics_client) { double(:epics_client) }
  let(:payment_provider) { PaymentProvider.new(config) }

  subject { Payments::EbicsImportJob.new }


  it 'does not run if no initialized config present' do
    expect(Payments::EbicsImport).to_not receive(:new)

    expect do
      perform_enqueued_jobs do
        subject.perform
      end
    end.to_not change { Payment.count }
  end

  it 'initializes payments' do
    config.update(status: :registered)

    allow(PaymentProvider).to receive(:new).and_return(payment_provider)
    allow(payment_provider).to receive(:client).and_return(epics_client)

    expect(epics_client).to receive(:HPB)

    expect(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

    expect(payment_provider).to receive(:Z54).and_return(invoice_file)

    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: people(:top_leader), recipient: people(:bottom_member), group: groups(:bottom_layer_one))
    InvoiceList.create(title: 'membership fee' ,invoices: [invoice])
    invoice.update!(reference: '20180314001221000006905084508206')

    expect do
      perform_enqueued_jobs do
        subject.perform
      end
    end.to change { Payment.count }.by(1)
  end

  private

  def read(name)
    Rails.root.join("spec/fixtures/invoices/#{name}.xml").read
  end
end
