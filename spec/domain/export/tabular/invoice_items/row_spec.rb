# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::InvoiceItems::Row do
  let(:invoice) { invoices(:invoice) }
  let(:item) { invoice_items(:pens) }

  subject(:row) { described_class.new(item) }

  it "takes the amounts from the item" do
    expect(row.fetch(:count)).to eq 3
    expect(row.fetch(:unit_cost)).to eq "1.50"
    expect(row.fetch(:cost)).to eq "4.50"
    expect(row.fetch(:vat_rate)).to eq 8
    expect(row.fetch(:vat)).to eq "0.36"
    expect(row.fetch(:total)).to eq "4.86"
  end

  it "takes the booking data from the item" do
    item.update!(account: "3001", cost_center: "310")
    expect(row.fetch(:account)).to eq "3001"
    expect(row.fetch(:cost_center)).to eq "310"
  end

  it "takes the remaining attributes from the invoice" do
    expect(row.fetch(:title)).to eq invoice.title
    expect(row.fetch(:sequence_number)).to eq invoice.sequence_number
    expect(row.fetch(:recipient_last_name)).to eq "Leader"
    expect(row.fetch(:payee_name)).to eq "Hitobito AG"
  end

  it "prefers the description of the invoice over the one of the item" do
    invoice.update!(description: "Invoice description")
    item.update!(description: "Item description")

    expect(row.fetch(:description)).to eq "Invoice description"
  end

  it "translates the state of the invoice" do
    expect(row.fetch(:state)).to eq "Entwurf"
  end
end
