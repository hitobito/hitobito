# frozen_string_literal: true

#  Copyright (c) 2021-2026, Hitobito AG. This file is part of
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

  it "is invalid when transaction_identifier already exists" do
    Payment.create!(amount: 10, transaction_identifier: "unique-uetr-123")
    payment = Payment.new(amount: 10, transaction_identifier: "unique-uetr-123")
    expect(payment).not_to be_valid
    expect(payment.errors[:transaction_identifier]).to be_present
  end

  it "is invalid when legacy_transaction_identifier matches an existing transaction_identifier" do
    Payment.create!(amount: 10, transaction_identifier: "legacy-txn-abc")
    payment = Payment.new(amount: 10,
      transaction_identifier: "new-uetr-xyz",
      legacy_transaction_identifier: "legacy-txn-abc")
    expect(payment).not_to be_valid
    expect(payment.errors[:transaction_identifier]).to be_present
  end

  it "is valid when neither transaction_identifier nor legacy_transaction_identifier exist yet" do
    Payment.create!(amount: 10, transaction_identifier: "some-other-txn")
    payment = Payment.new(amount: 10,
      transaction_identifier: "new-uetr-xyz",
      legacy_transaction_identifier: "legacy-txn-abc")
    expect(payment).to be_valid
  end

  it "is invalid when transaction_identifier matches case-insensitively" do
    Payment.create!(amount: 10, transaction_identifier: "UNIQUE-UETR-123")
    payment = Payment.new(amount: 10, transaction_identifier: "unique-uetr-123")
    expect(payment).not_to be_valid
    expect(payment.errors[:transaction_identifier]).to be_present
  end

  it "takes layer of invoice group" do
    invoice.update_columns(group_id: groups(:bottom_group_one_one).id)
    payment = Payment.create!(amount: 10, invoice: invoice, layer_group: groups(:top_layer))
    expect(payment.layer_group).to eq groups(:bottom_layer_one)
  end

  describe ".of_layer" do
    let(:layer) { groups(:bottom_layer_one) }
    let!(:assigned) { Fabricate(:payment, invoice: invoice) }
    let!(:unassigned) { Fabricate(:payment, invoice: nil, layer_group: layer) }
    let!(:unassigned_other_layer) { Fabricate(:payment, invoice: nil, layer_group: groups(:bottom_layer_two)) }
    let!(:unassigned_without_group) { Fabricate(:payment, invoice: nil, layer_group: nil) }

    it "contains assigned and unassigned payments of layer" do
      expect(Payment.of_layer(layer)).to match_array [assigned, unassigned]
    end

    it "contains unassigned payments without layer in root layer" do
      expect(Payment.of_layer(groups(:top_layer))).to eq [unassigned_without_group]
    end
  end
end
