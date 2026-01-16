# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeriodInvoiceTemplate::Item do
  let(:period_invoice_template) { Fabricate(:period_invoice_template) }

  subject(:item) do
    described_class.new(
      period_invoice_template:,
      type: "PeriodInvoiceTemplate::Item",
      account: "1234",
      cost_center: "5678",
      name: "invoice item"
    )
  end

  context "validation" do
    it "is invalid if instantiated as the abstract base class" do
      expect(item).not_to be_valid
    end
  end

  context "to_invoice_item" do
    it "passes on params by default" do
      expect(item).to receive(:invoice_item_class).and_return(InvoiceItem)
      result = item.to_invoice_item
      expect(result).to be_an_instance_of(InvoiceItem)
      expect(result.attributes.with_indifferent_access).to include({
        dynamic_cost_parameters: {
          group_id: period_invoice_template.group_id,
          period_start_on: period_invoice_template.start_on,
          period_end_on: period_invoice_template.end_on
        }
      })
      expect(result.attributes).to include(item.attributes.slice(:account, :cost_center, :name))
    end
  end

  context "invoice_item_class" do
    it "calculates the invoice item class automatically" do
      expect { item.invoice_item_class }.to raise_error(
        NameError, "uninitialized constant Invoice::Item"
      )
    end
  end
end
