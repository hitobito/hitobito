# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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

  it "creating a big enough payment marks invoice as payed" do
    expect do
      invoice.payments.create!(amount: invoice.total)
    end.to change { invoice.state }
    expect(invoice.state).to eq "payed"
    expect(invoice.amount_open).to eq 0.0
  end

  it "creating a smaller payment does not change invoice state" do
    expect do
      invoice.payments.create!(amount: invoice.total - 1)
    end.not_to change { invoice.state }
    expect(invoice.amount_open).to eq 1.0
  end

  it "allows multiple payments for same invoice without reference" do
    invoice.payments.create!(amount: invoice.total - 1)
    expect(invoice.payments.build(amount: 1)).to be_valid
  end

  it "rejects multiple payments for same invoice without same reference" do
    invoice.payments.create!(amount: invoice.total - 1, reference: 1)
    expect(invoice.payments.build(amount: 1, reference: 1)).not_to be_valid
  end

end
