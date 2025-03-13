# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

require "spec_helper"

describe Payments::EbicsImportJob do
  include ActiveJob::TestHelper

  let(:invoice_files) {
    [read("camt.054-ESR-ASR_T_CH0209000000857876452_378159670_0_2018031411011923")]
  }

  let(:invalid_invoice_files) {
    [read("camt.054-invalid")]
  }
  let(:config) { payment_provider_configs(:postfinance) }
  let(:epics_client) { double(:epics_client) }
  let(:payment_provider) { PaymentProvider.new(config) }

  subject { Payments::EbicsImportJob.new(config.id) }

  it "initializes payments and logs" do
    config.update(status: :registered)

    allow(PaymentProvider).to receive(:new).and_return(payment_provider)
    allow(payment_provider).to receive(:client).and_return(epics_client)

    expect(epics_client).to receive(:HPB)

    expect(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

    expect(payment_provider).to receive(:Z54).and_return(invoice_files)

    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: people(:top_leader), recipient: people(:bottom_member), group: groups(:bottom_layer_one))
    InvoiceList.create(title: "membership fee", invoices: [invoice])
    invoice.update!(reference: "000000000000100000000000800")

    expect do
      subject.perform
    end.to change { HitobitoLogEntry.count }.by(2)

    expect(invoice.payments.size).to eq(1)

    start_log, error_log = HitobitoLogEntry.last(2)
    expect(start_log.category).to eq("ebics")
    expect(start_log.level).to eq("info")
    expect(start_log.message).to eq("Starting Ebics payment import")
    expect(start_log.subject).to eq(config)
    expect(start_log.payload).to be_nil

    expect(error_log.category).to eq("ebics")
    expect(error_log.level).to eq("info")
    expect(error_log.message).to eq("Successfully imported 5 payments")
    expect(error_log.subject).to eq(config)
    expect(error_log.payload).to include({"imported_payments_count" => 1,
                                           "without_invoice_count" => 4,
                                           "invalid_payments_count" => 0,
                                           "invalid_payments" => {},
                                           "errors" => []})
  end

  it "catches error raised on provider" do
    config.update(status: :registered)

    failing_provider = double

    expect(PaymentProvider).to receive(:new).with(config).exactly(:once).and_return(failing_provider)

    error = Epics::Error::TechnicalError.new("091010")
    expect(failing_provider).to receive(:HPB).and_raise(error)

    expect(Airbrake).to receive(:notify)
      .exactly(:once)
      .with(error, hash_including(parameters: {payment_provider_config: config}))

    expect do
      subject.perform
    end.to change { HitobitoLogEntry.count }.by(2)

    start_log, error_log = HitobitoLogEntry.last(2)
    expect(start_log.category).to eq("ebics")
    expect(start_log.level).to eq("info")
    expect(start_log.message).to eq("Starting Ebics payment import")
    expect(start_log.subject).to eq(config)
    expect(start_log.payload).to be_nil

    expect(error_log.category).to eq("ebics")
    expect(error_log.level).to eq("error")
    expect(error_log.message).to eq("Could not import payment from Ebics")
    expect(error_log.subject).to eq(config)
    expect(error_log.payload).to eq({"error" => error.detailed_message})
  end

  it "catches error raised on payment xml process" do
    config.update(status: :registered)

    allow(PaymentProvider).to receive(:new).and_return(payment_provider)
    allow(payment_provider).to receive(:client).and_return(epics_client)

    expect(epics_client).to receive(:HPB)

    expect(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

    expect(payment_provider).to receive(:Z54).and_return(invalid_invoice_files)

    expect(Airbrake).to receive(:notify)
      .exactly(:once)
      .with(kind_of(REXML::ParseException), hash_including(parameters: {payment_provider_config: config}))

    expect do
      subject.perform
    end.to change { HitobitoLogEntry.count }.by(2)

    start_log, error_log = HitobitoLogEntry.last(2)
    expect(start_log.category).to eq("ebics")
    expect(start_log.level).to eq("info")
    expect(start_log.message).to eq("Starting Ebics payment import")
    expect(start_log.subject).to eq(config)
    expect(start_log.payload).to be_nil

    expect(error_log.category).to eq("ebics")
    expect(error_log.level).to eq("error")
    expect(error_log.message).to eq("Could not import payment from Ebics")
    expect(error_log.subject).to eq(config)
    expect(error_log.payload["error"]).to include("REXML::ParseException")
    expect(error_log.attachment).to be_attached
  end

  describe "#log_result" do
    before do
      config.update(status: :registered)

      allow(PaymentProvider).to receive(:new).and_return(payment_provider)
      allow(payment_provider).to receive(:client).and_return(epics_client)

      allow(epics_client).to receive(:HPB)

      allow(payment_provider).to receive(:check_bank_public_keys!).and_return(true)

      allow(payment_provider).to receive(:Z54).and_return(invoice_files)

      invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: people(:top_leader), recipient: people(:bottom_member), group: groups(:bottom_layer_one))
      InvoiceList.create(title: "membership fee", invoices: [invoice])
      invoice.update!(reference: "000000000000100000000000800")
    end

    it "includes payments count" do
      subject.perform

      expect(subject.log_results).to match(
        imported_payments_count: 1,
        without_invoice_count: 4,
        invalid_payments_count: 0,
        invalid_payments: {},
        errors: []
      )
    end

    it "includes validation error messages" do
      allow_any_instance_of(Payment).to receive(:save) do |payment|
        # let's fake a validation error
        payment.amount = nil
        payment.validate
        false
      end

      subject.perform

      expect(subject.log_results[:invalid_payments]).to have(5).items
      expect(subject.log_results[:invalid_payments].values.first).to match(amount: ["muss ausgefüllt werden"])
    end

    it "includes errors" do
      error = Epics::Error::TechnicalError.new("091010")
      allow_any_instance_of(PaymentProvider).to receive(:HPB).and_raise(error)

      subject.perform

      expect(subject.log_results[:errors]).to include(error)
    end
  end

  private

  def read(name)
    Rails.root.join("spec/fixtures/invoices/#{name}.xml").read
  end
end
