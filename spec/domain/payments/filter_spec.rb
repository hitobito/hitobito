# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Payments::Filter do
  let(:group) { groups(:bottom_layer_one) }
  let(:today) { Time.zone.parse("2026-06-04 10:00:00") }

  let(:base_scope) do
    Payment.includes(:invoice).joins(<<~SQL)
      LEFT JOIN invoices ON payments.invoice_id = invoices.id
      LEFT JOIN people ON people.id = invoices.recipient_id AND invoices.recipient_type = 'Person'
      LEFT JOIN groups ON groups.id = invoices.recipient_id AND invoices.recipient_type = 'Group'
    SQL
  end

  def create_invoice(amount)
    Fabricate(:invoice, {
      group: group,
      state: "sent",
      issued_at: Time.zone.today,
      sent_at: 10.days.ago.to_date,
      due_at: 20.days.from_now.to_date,
      invoice_items: [Fabricate.build(:invoice_item, unit_cost: amount, count: 1)]
    })
  end

  let!(:manually_created_payment) do
    Fabricate(:payment, {
      invoice: create_invoice(100.0),
      status: "manually_created",
      received_at: 1.month.ago.to_date,
      amount: 100.0
    }).tap { |p| p.send(:update_invoice) }
  end

  let!(:ebics_imported_payment) do
    Fabricate(:payment, {
      invoice: create_invoice(100.0),
      status: "ebics_imported",
      received_at: 2.weeks.ago.to_date,
      amount: 50.0
    }).tap { |p| p.send(:update_invoice) }
  end

  let!(:xml_imported_payment) do
    Fabricate(:payment, {
      invoice: create_invoice(100.0),
      status: "xml_imported",
      received_at: 1.week.ago.to_date,
      amount: 150.0
    }).tap { |p| p.send(:update_invoice) }
  end

  let!(:unassigned_xml_imported_payment) do
    Fabricate(:payment, invoice: nil, status: "xml_imported", received_at: 1.days.ago.to_date)
  end

  let!(:unassigned_payment) do
    Fabricate(:payment, invoice: nil, status: "without_invoice", received_at: 3.days.ago.to_date)
  end

  around do |example|
    travel_to(today) do
      example.call
    end
  end

  it "filters by payment status 'manually created'" do
    filtered = described_class.new(status: "manually_created").apply(base_scope)

    expect(filtered).to match_array([manually_created_payment])
  end

  it "filters by payment status 'ebics imported'" do
    filtered = described_class.new(status: "ebics_imported").apply(base_scope)

    expect(filtered).to match_array([ebics_imported_payment])
  end

  it "filters by payment status 'xml imported'" do
    filtered = described_class.new(status: "xml_imported").apply(base_scope)

    expect(filtered).to match_array([xml_imported_payment, unassigned_xml_imported_payment])
  end

  it "handles legacy case of without_invoice == unassigned" do
    filtered = described_class.new(status: "without_invoice").apply(base_scope)

    expect(filtered).to match_array([unassigned_payment, unassigned_xml_imported_payment])
  end

  it "filters by invoice state 'payed'" do
    expect(manually_created_payment).to be_settles # one, that settles
    expect(manually_created_payment.invoice.state).to eq "payed"

    filtered = described_class.new(invoice_status: "payed").apply(base_scope)

    expect(filtered).to match_array([manually_created_payment])
  end

  it "filters by invoice state 'partial'" do
    expect(ebics_imported_payment).to be_undercuts # one, that undercuts

    filtered = described_class.new(invoice_status: "partial").apply(base_scope)

    expect(filtered).to match_array([ebics_imported_payment])
  end

  it "filters by invoice state 'excess'" do
    expect(xml_imported_payment).to be_exceeds # one, that exceeds

    filtered = described_class.new(invoice_status: "excess").apply(base_scope)

    expect(filtered).to match_array([xml_imported_payment])
  end

  it "filters by id" do
    ids = [ebics_imported_payment.id, xml_imported_payment.id].join(",")

    filtered = described_class.new(ids: ids).apply(base_scope)

    expect(filtered).to match_array([ebics_imported_payment, xml_imported_payment])
  end

  it "filters by daterange" do
    filtered = described_class.new(
      from: 10.days.ago.to_date.to_s,
      to: 2.day.ago.to_date.to_s
    ).apply(base_scope)

    expect(filtered).to match_array([xml_imported_payment, unassigned_payment])
  end

  it "return all without filter" do
    filtered = described_class.new.apply(base_scope)

    expect(filtered).to match_array([
      xml_imported_payment,
      unassigned_xml_imported_payment,
      unassigned_payment,
      ebics_imported_payment,
      manually_created_payment
    ])
  end
end
