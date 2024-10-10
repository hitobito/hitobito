# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id                     :integer          not null, primary key
#  amount                 :decimal(12, 2)   not null
#  received_at            :date             not null
#  reference              :string
#  status                 :string
#  transaction_identifier :string
#  transaction_xml        :text
#  invoice_id             :integer
#
# Indexes
#
#  index_payments_on_invoice_id              (invoice_id)
#  index_payments_on_transaction_identifier  (transaction_identifier) UNIQUE
#

require "spec_helper"

describe Payment do
  let(:invoice) { invoices(:sent) }

  it "accepts esr_number in hash passed in constructor" do
    payment = Payment.new(esr_number: 1)
    expect(payment.esr_number).to eq 1
  end

  it "reads esr_number from invoice if invoice is passed" do
    payment = Payment.new(esr_number: 1, invoice: invoice)
    expect(payment.esr_number).to eq invoice.esr_number
  end

  it "marks invoice as payed with a big enough payment" do
    expect do
      invoice.payments.create!(amount: invoice.total)
    end.to change(invoice, :state).to("payed")

    expect(invoice.amount_open).to eq 0.0
  end

  it "marks invoice as partial with a smaller payment" do
    expect do
      invoice.payments.create!(amount: invoice.total - 1)
    end.to change(invoice, :state).to("partial")

    expect(invoice.amount_open).to eq 1.0
  end

  it "marks invoice as excess with a bigger payment" do
    expect do
      invoice.payments.create!(amount: invoice.total + 1)
    end.to change(invoice, :state).to("excess")

    expect(invoice.amount_open).to eq(-1.0)
  end

  it "allows multiple payments for same invoice without reference" do
    invoice.payments.create!(amount: invoice.total - 1)
    expect(invoice.payments.build(amount: 1)).to be_valid
  end

  it "allows multiple payments for same invoice with same reference" do
    invoice.payments.create!(amount: invoice.total - 1, reference: 1)
    expect(invoice.payments.build(amount: 1, reference: 1)).to be_valid
  end
end
