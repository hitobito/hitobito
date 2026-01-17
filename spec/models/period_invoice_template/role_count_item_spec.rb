# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeriodInvoiceTemplate::RoleCountItem do
  let(:period_invoice_template) { Fabricate(:period_invoice_template) }

  subject(:item) do
    described_class.new(
      period_invoice_template:,
      account: "1234",
      cost_center: "5678",
      name: "invoice item",
      dynamic_cost_parameters: {
        role_types: [Group::TopGroup::Leader.name],
        unit_cost: 10.50
      }
    )
  end

  context "validation" do
    it "is valid" do
      expect(item).to be_valid
    end

    it "is invalid without role types" do
      item.dynamic_cost_parameters[:role_types] = nil
      expect(item).not_to be_valid
    end

    it "is invalid with wrong unit_cost value" do
      item.dynamic_cost_parameters[:unit_cost] = "foobar"
      expect(item).not_to be_valid
    end

    it "is invalid with nil unit_cost" do
      item.dynamic_cost_parameters[:unit_cost] = nil
      expect(item).not_to be_valid
    end
  end

  context "to_invoice_item" do
    it "passes on params" do
      result = item.to_invoice_item
      expect(result).to be_an_instance_of(Invoice::RoleCountItem)
      expect(result.attributes.with_indifferent_access).to include({
        dynamic_cost_parameters: {
          group_id: period_invoice_template.group_id,
          period_start_on: period_invoice_template.start_on,
          period_end_on: period_invoice_template.end_on,
          role_types: [Group::TopGroup::Leader.name],
          unit_cost: 10.50
        }
      })
      expect(result.attributes).to include(item.attributes.slice(:account, :cost_center, :name))
    end
  end

  context "invoice_item_class" do
    it "returns the invoice item class" do
      expect(item.invoice_item_class).to eq(Invoice::RoleCountItem)
    end
  end
end
