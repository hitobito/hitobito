# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: invoice_items
#
#  id                      :integer          not null, primary key
#  account                 :string
#  cost                    :decimal(12, 2)
#  cost_center             :string
#  count                   :integer          default(1), not null
#  description             :text
#  dynamic_cost_parameters :text
#  name                    :string           not null
#  type                    :string           default("InvoiceItem"), not null
#  unit_cost               :decimal(12, 2)   not null
#  vat_rate                :decimal(5, 2)
#  invoice_id              :integer          not null
#
# Indexes
#
#  index_invoice_items_on_invoice_id  (invoice_id)
#
require "spec_helper"

describe InvoiceItem::FixedFee do
  subject(:item) { described_class.new }

  describe "#name" do
    it "raises with incomplete values" do
      expect { item.name }.to raise_error(ArgumentError, "Translation missing: de.fixed_fees")
    end

    context "with values" do
      before do
        item.name = :members
        item.dynamic_cost_parameters = {fixed_fees: :membership}
      end

      it "uses name value with dynamic_cost_parameters for i18n translation" do
        expect(item.name).to eq "Mitgliedsbeitrag - Members"
        expect(I18n.with_locale(:fr) { item.name }).to eq "Cotisation - Members"
        expect(I18n.with_locale(:en) { item.name }).to eq "Mitglieder"
      end
    end
  end

  describe "readonly attrs" do
    let!(:item) do
      described_class.create!(
        invoice_id: invoices(:invoice).id,
        name: :members,
        dynamic_cost_parameters: {fixed_fees: :membership},
        unit_cost: 10
      )
    end

    it "silently ignores updates to name" do
      item.update!(name: "test")
      expect(item.reload.read_attribute(:name)).to eq "members"
    end

    it "silently ignores updates to dynamic_cost_parameters" do
      item.update!(dynamic_cost_parameters: {foo: :bar})
      expect(item.reload.read_attribute(:dynamic_cost_parameters)).to eq({fixed_fees: :membership})
    end
  end
end
