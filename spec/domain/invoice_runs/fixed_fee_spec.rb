# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceRuns::FixedFee do
  let(:list) { InvoiceRun.new(invoice: Invoice.new) }

  subject(:fee) { described_class.for(:membership) }

  describe "::for" do
    it "raises if config is not found" do
      expect { described_class.for(:unknown) }.to raise_error(RuntimeError, "No config exists for unknown")
    end
  end

  describe "#receivers" do
    it "includes top leader" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      expect(fee.receivers.roles).to eq [role]
    end
  end

  describe "#items" do
    it "has an invoice item for each configured membership fee item" do
      expect(fee).to have(2).items
      members, leaders = fee.items
      expect(members).to be_kind_of(InvoiceRuns::RoleItem)
      expect(leaders).to be_kind_of(InvoiceRuns::RoleItem)
    end

    it "builds item with translated name and dynamic_cost_parameter" do
      members, leaders = fee.invoice_items
      expect(members.name).to eq "Mitgliedsbeitrag - Members"
      expect(leaders.name).to eq "Mitgliedsbeitrag - Leaders"
      expect(members[:dynamic_cost_parameters][:fixed_fees]).to eq :membership
      expect(leaders[:dynamic_cost_parameters][:fixed_fees]).to eq :membership
    end
  end

  describe "#prepare" do
    let(:flash) {}
    let(:list) { InvoiceRun.new(invoice: Invoice.new) }
    let(:layer_one) { groups(:bottom_layer_one) }
    let(:layer_two) { groups(:bottom_layer_two) }

    it "sets recipient_ids and invoice items" do
      person_one = Fabricate(Group::BottomLayer::Leader.sti_name, group: layer_one).person
      person_two = Fabricate(Group::BottomLayer::Leader.sti_name, group: layer_two).person
      Fabricate(Group::BottomLayer::Member.sti_name, group: layer_two).person
      fee.prepare(list)

      expect(list.receivers).to eq [
        InvoiceRuns::Receiver.new(id: person_one.id, layer_group_id: layer_one.id),
        InvoiceRuns::Receiver.new(id: person_two.id, layer_group_id: layer_two.id)
      ]
      expect(list.invoice).to have(2).invoice_items
      leaders, members = list.invoice.invoice_items
      expect(members.count).to eq 2
      expect(leaders.count).to eq 2
      expect(list.invoice.recalculate).to eq 50
    end

    it "counts only roles of receivers" do
      person_one = Fabricate(Group::BottomLayer::Leader.sti_name, group: layer_one).person
      fee.prepare(list)
      expect(list.receivers).to eq [
        InvoiceRuns::Receiver.new(id: person_one.id, layer_group_id: layer_one.id)
      ]
      leaders, members = list.invoice.invoice_items
      expect(members.count).to eq 1
      expect(leaders.count).to eq 1
      expect(list.invoice.recalculate).to eq 25
    end

    it "yields missing warning with missing receivers" do
      expect { |b| fee.prepare(list, &b) }.to yield_with_args([:warning,
        "Für folgende Gruppen konnte kein Empfänger ermittelt werden: Bottom One, Bottom Two"])
    end

    it "does not yield if all expected receivers are present" do
      Fabricate(Group::BottomLayer::Leader.sti_name, group: layer_one).person
      Fabricate(Group::BottomLayer::Leader.sti_name, group: layer_two).person
      expect { |b| fee.prepare(list, &b) }.not_to yield_control
    end
  end
end
