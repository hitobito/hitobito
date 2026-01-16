# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::RoleCountItem do
  # TODO extend this spec to test the business logic
  let(:group) { groups(:top_group) }
  let(:role_types) { [Group::TopGroup::Leader.name] }
  let(:invoice) { Fabricate(:invoice, group:) }
  subject(:item) do
    described_class.new(
      invoice:,
      account: "1234",
      cost_center: "5678",
      name: "invoice item",
      dynamic_cost_parameters: {
        group_id: group.id,
        role_types:,
        unit_cost: 10.50,
        period_start_on: 1.month.ago,
        period_end_on: 1.month.from_now
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

    it "can work with group id dynamic cost parameters" do
      invoice.group_id = nil
      expect(item).to be_valid
    end

    it "can fallback to group id from invoice" do
      item.dynamic_cost_parameters[:group_id] = nil
      expect(item).to be_valid
    end

    it "is invalid without group id" do
      item.dynamic_cost_parameters[:group_id] = nil
      item.invoice.group_id = nil
      expect(item).not_to be_valid
    end

    it "is invalid without period start" do
      item.dynamic_cost_parameters[:period_start_on] = nil
      expect(item).not_to be_valid
    end

    it "is valid without period end" do
      item.dynamic_cost_parameters[:period_end_on] = nil
      expect(item).to be_valid
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

  context "#count" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:role_types) { [Group::BottomGroup::Leader.name] }

    before do
      Group::BottomGroup::Leader.destroy_all
      #item.dynamic_cost_parameters[:group_id] =
    end

    context "with no recipient" do
      it "counts matching roles" do
        expect(item.count).to eq(0)

        Fabricate(Group::BottomGroup::Leader.name, group:)
        item.instance_variable_set(:@count, nil)

        expect(item.count).to eq(1)
      end

      it "ignores inactive role" do
        Fabricate(Group::BottomGroup::Leader.name, group:,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.count).to eq(0)
      end

      it "ignores future role" do
        Fabricate(Group::BottomGroup::Leader.name, group:,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.count).to eq(0)
      end

      it "considers past role which overlaps the period" do
        item.dynamic_cost_parameters[:period_start_on] = 11.months.ago
        item.dynamic_cost_parameters[:period_end_on] = 9.months.ago
        Fabricate(Group::BottomGroup::Leader.name, group:,
          start_on: 12.months.ago, end_on: 10.months.ago)
        expect(item.count).to eq(1)
      end

      it "ignores roles outside of the group" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_two))
        expect(item.count).to eq(0)
      end

      it "searches deep within the group" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one))
        expect(item.count).to eq(1)
      end

      it "ignores role of the wrong type" do
        Fabricate(Group::BottomGroup::Member.name, group:)
        expect(item.count).to eq(0)
      end

      it "falls back to group_id of the invoice" do
        group2 = groups(:bottom_group_one_two)
        item.dynamic_cost_parameters[:group_id] = nil
        invoice.group_id = group2.id
        Fabricate(Group::BottomGroup::Leader.name, group: group2)
        expect(item.count).to eq(1)
      end

      it "prefers the group_id from the params" do
        group2 = groups(:bottom_group_one_two)
        item.dynamic_cost_parameters[:group_id] = group2.id
        invoice.group_id = group.id
        Fabricate(Group::BottomGroup::Leader.name, group: group2)
        expect(item.count).to eq(1)
      end

      it "counts multiple roles of the same person and same group as one" do
        role1 = Fabricate(Group::BottomGroup::Leader.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group:, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end

      it "counts multiple roles of separate people separately" do
        Fabricate(Group::BottomGroup::Leader.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end

      it "counts multiple roles of the same person in separate groups separately" do
        group2 = groups(:bottom_group_one_one_one)
        role1 = Fabricate(Group::BottomGroup::Leader.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group: group2, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end

      it "counts multiple roles with separate types of the same person and same group as one" do
        item.dynamic_cost_parameters[:role_types] =
          [Group::BottomGroup::Leader.name, Group::BottomGroup::Member.name]
        role1 = Fabricate(Group::BottomGroup::Leader.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Member.name, group:, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end
    end

    context "with group recipient" do
      # TODO
    end

    context "with person recipient" do
      # TODO
    end
  end

  context "#dynamic_cost" do
    it "multiplies price and count" do
      Fabricate(Group::TopGroup::Leader.name, group:)
      expect(item.dynamic_cost).to eq(21.00)
    end
  end
end
