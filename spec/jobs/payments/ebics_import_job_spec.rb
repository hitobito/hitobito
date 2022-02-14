# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

require 'spec_helper'

describe Payments::EbicsImportJob do
  include ActiveJob::TestHelper

  let(:invoice_files) {
    [read('camt.054-ESR-ASR_T_CH0209000000857876452_378159670_0_2018031411011923')]
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

  it 'reschedules to tomorrow at midnight' do
    perform_enqueued_jobs do
      subject.perform
    end

    expect(subject.delayed_jobs.last.run_at).to eq(Time.zone.tomorrow.beginning_of_day.in_time_zone)
  end

  it 'initializes payments' do
    config.update(status: :registered)

    allow(PaymentProvider).to receive(:new).and_return(payment_provider)
    allow(payment_provider).to receive(:client).and_return(epics_client)

    expect(epics_client).to receive(:HPB)

    expect(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

    expect(payment_provider).to receive(:Z54).and_return(invoice_files)

    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: people(:top_leader), recipient: people(:bottom_member), group: groups(:bottom_layer_one))
    InvoiceList.create(title: 'membership fee', invoices: [invoice])
    invoice.update!(reference: '000000000000100000000000800')

    expect do
      perform_enqueued_jobs do
        subject.perform
      end
    end.to change { Payment.count }.by(1)
  end

  it 'continues after error is raised on provider' do
    failing_config = payment_provider_configs(:ubs)

    config.update(status: :registered)
    failing_config.update( status: :registered)

    failing_provider = double

    expect(PaymentProvider).to receive(:new).with(config).exactly(:once).and_call_original
    expect(PaymentProvider).to receive(:new).with(failing_config).exactly(:once).and_return(failing_provider)

    error = Epics::Error::TechnicalError.new('091010')
    expect(failing_provider).to receive(:HPB).and_raise(error)

    expect(Airbrake).to receive(:notify)
                    .exactly(:once)
                    .with(error, hash_including(parameters: { payment_provider_config: failing_config }))
    expect(Raven).to receive(:capture_exception)
                 .exactly(:once)
                 .with(error, logger: 'delayed_job')

    expect(PaymentProvider).to receive(:new).and_return(payment_provider)
    expect(payment_provider).to receive(:client).and_return(epics_client)

    expect(epics_client).to receive(:HPB)

    expect(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

    expect(payment_provider).to receive(:Z54).and_return(invoice_files)

    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: people(:top_leader), recipient: people(:bottom_member), group: groups(:bottom_layer_one))
    InvoiceList.create(title: 'membership fee' ,invoices: [invoice])
    invoice.update!(reference: '000000000000100000000000800')

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
