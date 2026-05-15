#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeriodInvoiceTemplate do
  let(:group) { groups(:top_layer) }
  let(:period_invoice_template) { Fabricate(:period_invoice_template) }
  let(:messages) { period_invoice_template.errors.full_messages }

  describe "::validations" do
    it "validates presence of name" do
      period_invoice_template.name = nil

      expect(period_invoice_template).not_to be_valid
      expect(messages).to include("Bezeichnung muss ausgefüllt werden")
    end

    it "validates presence of start_on" do
      period_invoice_template.start_on = nil

      expect(period_invoice_template).not_to be_valid
      expect(messages).to include("Rechnungsperiode Start muss ausgefüllt werden")
    end

    it "validates end_on to be after start_on" do
      period_invoice_template.start_on = period_invoice_template.end_on + 1.day

      expect(period_invoice_template).not_to be_valid
      expect(messages).to include("Rechnungsperiode Ende kann nicht vor Rechnungsperiode Start sein")
    end

    it "validates recipient_source.group_type" do
      period_invoice_template.recipient_source.group_type = nil
      expect(period_invoice_template).not_to be_valid
      expect(messages).to include("Empfängergruppen muss ausgefüllt werden")
      period_invoice_template.recipient_source.group_type = "foobar"
      expect(period_invoice_template).not_to be_valid
      expect(messages).to include("Empfängergruppen muss ausgefüllt werden")
      period_invoice_template.recipient_source.group_type = Group::TopLayer.name
      expect(period_invoice_template).to be_valid
    end

    it "prevents changes to recipient_source when invoice runs are present" do
      period_invoice_template.recipient_source.group_type = Group::TopLayer.name
      expect(period_invoice_template).to be_valid
      period_invoice_template.invoice_runs.build
      expect(period_invoice_template).not_to be_valid
      expect(messages).to include("Rechnungsempfänger darf nicht mehr verändert werden, da bereits " \
        "Rechnungsläufe existieren")
    end
  end

  it "#to_s returns name" do
    expect(period_invoice_template.to_s).to eq(period_invoice_template.name)
  end

  describe "#duplicate" do
    let(:recipient_source) do
      GroupsFilter.new(parent: Group.root, group_type: Group::BottomLayer.name, active_at: Time.zone.today)
    end
    let(:item_attributes) do
      {
        name: "Mitgliedsbeitrag",
        type: PeriodInvoiceTemplate::RoleCountItem.name,
        dynamic_cost_parameters: {
          unit_cost: "5.00", role_types: [Group::TopGroup::Leader.name]
        }
      }
    end

    let(:template) do
      PeriodInvoiceTemplate.create!(
        name: "test",
        group:,
        recipient_source:,
        start_on: Date.new(2026, 5, 10),
        end_on: Date.new(2026, 10, 10),
        items_attributes: [item_attributes]
      )
    end

    it "copies main attributes and item" do
      duplicated = template.duplicate
      expect(duplicated.name).to eq "test"
      expect(duplicated.group).to eq group
      expect(duplicated.recipient_source).to eq recipient_source
      expect(duplicated.items).to have(1).item

      item_attrs = duplicated.items.first.attributes.compact_blank.except("name_de").deep_symbolize_keys
      expect(item_attrs).to eq(item_attributes)
    end

    it "duplicated starts today and has end_on nil if end_on is missing on source" do
      template.update!(start_on: Date.new(2026, 5, 10), end_on: nil)
      duplicated = template.duplicate
      expect(duplicated.start_on).to eq Time.zone.today
      expect(duplicated.end_on).to be_nil
    end

    it "duplicated starts one day after source end_on and has duration of source if end_on is set on source" do
      template.update!(start_on: Date.new(2026, 5, 10), end_on: Date.new(2026, 5, 15))
      duplicated = template.duplicate
      expect(duplicated.start_on).to eq Date.new(2026, 5, 16)
      expect(duplicated.end_on).to eq Date.new(2026, 5, 21)
    end

    it "caters for source leap year" do
      template.update!(start_on: Date.new(2026, 1, 1), end_on: Date.new(2026, 12, 31))
      duplicated = template.duplicate
      expect(duplicated.start_on).to eq Date.new(2027, 1, 1)
      expect(duplicated.end_on).to eq Date.new(2027, 12, 31)
    end

    it "caters for duplicate leap year" do
      template.update!(start_on: Date.new(2025, 1, 1), end_on: Date.new(2025, 12, 31))
      duplicated = template.duplicate
      expect(duplicated.start_on).to eq Date.new(2026, 1, 1)
      expect(duplicated.end_on).to eq Date.new(2026, 12, 31)
    end
  end
end
