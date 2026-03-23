# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::RoleCountItem do
  let(:group) { groups(:top_group) }
  let(:role_types) { [Group::TopGroup::Leader.name] }
  let(:invoice) { Fabricate(:invoice, group:) }
  let(:template_item_id) { 1337 }
  let(:attrs) {
    {
      invoice:,
      account: "1234",
      cost_center: "5678",
      name: "invoice item",
      dynamic_cost_parameters: {
        template_item_id:,
        role_types:,
        unit_cost: 10.50,
        period_start_on: 1.month.ago,
        period_end_on: 1.month.from_now
      }
    }
  }

  subject(:item) { described_class.new(**attrs) }

  context "validation" do
    it "is valid" do
      expect(item).to be_valid
    end

    it "is invalid without role types" do
      item.dynamic_cost_parameters[:role_types] = nil
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
    end

    context "with a list of group recipients, calculating preview values for a whole invoice run" do
      let(:recipient_groups) { Group.where(id: [group.id, groups(:bottom_group_two_one).id]) }

      subject(:item) { described_class.for_groups(recipient_groups, **attrs) }

      it "counts matching roles" do
        expect(item.count).to eq(0)

        Fabricate(Group::BottomGroup::Leader.name, group:)
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_two_one))

        expect(item.recalculate.count).to eq(2)
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

      it "ignores roles outside of the specified groups" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_two))
        expect(item.count).to eq(0)
      end

      it "searches deep within the group" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one))
        expect(item.count).to eq(1)
      end

      context "with nested recipient groups" do
        let(:recipient_groups) { Group.where(id: [group.id, groups(:bottom_group_one_one_one).id]) }

        it "counts the same role once for each of the specified groups" do
          Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one))
          expect(item.count).to eq(2)
        end
      end

      it "ignores role of the wrong type" do
        Fabricate(Group::BottomGroup::Member.name, group:)
        expect(item.count).to eq(0)
      end

      it "ignores roles which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(0)
      end

      it "ignores roles in subgroups which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one))
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(0)
      end

      it "counts roles even when subject with different id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id + 1,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different item_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id + 1)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:)
        previous_invoice = Fabricate(:invoice, recipient_id: group.id + 1, recipient_type: "Group", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:)
        previous_invoice = Fabricate(:invoice, recipient_id: group.id, recipient_type: "Person", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

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

    context "with single group recipient" do
      let(:group) { groups(:bottom_layer_one) }
      let(:recipient_group) { groups(:bottom_group_one_one) }

      subject(:item) { described_class.for_groups(recipient_group.id, **attrs) }

      before do
        item.invoice.recipient = recipient_group
      end

      it "counts matching roles" do
        expect(item.count).to eq(0)

        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)

        expect(item.recalculate.count).to eq(1)
      end

      it "ignores inactive role" do
        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.count).to eq(0)
      end

      it "ignores future role" do
        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.count).to eq(0)
      end

      it "considers past role which overlaps the period" do
        item.dynamic_cost_parameters[:period_start_on] = 11.months.ago
        item.dynamic_cost_parameters[:period_end_on] = 9.months.ago
        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 12.months.ago, end_on: 10.months.ago)
        expect(item.count).to eq(1)
      end

      it "ignores roles outside of the recipient group" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_two))
        expect(item.count).to eq(0)
      end

      it "searches deep within the group" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one))
        expect(item.count).to eq(1)
      end

      it "ignores role of the wrong type" do
        Fabricate(Group::BottomGroup::Member.name, group: recipient_group)
        expect(item.count).to eq(0)
      end

      it "ignores roles which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient: recipient_group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(0)
      end

      it "ignores roles in subgroups which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one))
        previous_invoice = Fabricate(:invoice, recipient: recipient_group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(0)
      end

      it "counts roles even when subject with different id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient: recipient_group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id + 1,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient: recipient_group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different item_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient: recipient_group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id + 1)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient_id: recipient_group.id + 1, recipient_type: "Group", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient_id: recipient_group.id, recipient_type: "Person", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "ignores group_id on the invoice" do
        group2 = groups(:bottom_group_one_two)
        item.invoice.group_id = group2.id
        Fabricate(Group::BottomGroup::Leader.name, group: group2)
        expect(item.count).to eq(0)

        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)

        expect(item.recalculate.count).to eq(1)
      end

      it "counts multiple roles of the same person and same group as one" do
        role1 = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end

      it "counts multiple roles of separate people separately" do
        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end

      it "counts multiple roles of the same person in separate groups separately" do
        group2 = groups(:bottom_group_one_one_one)
        role1 = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group: group2, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end

      it "counts multiple roles with separate types of the same person and same group as one" do
        item.dynamic_cost_parameters[:role_types] =
          [Group::BottomGroup::Leader.name, Group::BottomGroup::Member.name]
        role1 = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Member.name, group: recipient_group, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end
    end

    context "with a list of person recipients, calculating preview values for a whole invoice run" do
      let(:person) { people(:bottom_member) }
      let(:person2) { people(:top_leader) }
      let(:recipient_people) { Person.where(id: [person.id, person2.id]) }

      subject(:item) { described_class.for_people(recipient_people, **attrs) }

      it "counts matching roles" do
        expect(item.count).to eq(0)

        Fabricate(Group::BottomGroup::Leader.name, group:, person:)

        expect(item.recalculate.count).to eq(1)
      end

      it "ignores inactive role" do
        Fabricate(Group::BottomGroup::Leader.name, group:, person:,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.count).to eq(0)
      end

      it "ignores future role" do
        Fabricate(Group::BottomGroup::Leader.name, group:, person:,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.count).to eq(0)
      end

      it "considers past role which overlaps the period" do
        item.dynamic_cost_parameters[:period_start_on] = 11.months.ago
        item.dynamic_cost_parameters[:period_end_on] = 9.months.ago
        Fabricate(Group::BottomGroup::Leader.name, group:, person:,
          start_on: 12.months.ago, end_on: 10.months.ago)
        expect(item.count).to eq(1)
      end

      it "ignores roles outside of the specified groups" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_two), person:)
        expect(item.count).to eq(0)
      end

      it "ignores roles of unrelated person" do
        Fabricate(Group::BottomGroup::Leader.name, group:, person: people(:root))
        expect(item.count).to eq(0)
      end

      it "searches deep within the group" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one),
          person:)
        expect(item.count).to eq(1)
      end

      it "ignores role of the wrong type" do
        Fabricate(Group::BottomGroup::Member.name, group:, person:)
        expect(item.count).to eq(0)
      end

      it "ignores roles which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(0)
      end

      it "ignores roles in subgroups which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one), person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(0)
      end

      it "counts roles even when subject with different id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id + 1,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different item_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id + 1)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient_id: person.id + 1, recipient_type: "Person", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient_id: person.id, recipient_type: "Group", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts multiple roles of the same person and same group as one" do
        Fabricate(Group::BottomGroup::Leader.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group:, person:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end

      it "counts multiple roles of separate people separately" do
        Fabricate(Group::BottomGroup::Leader.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group:, person: person2,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end

      it "counts multiple roles of the same person in separate groups separately" do
        group2 = groups(:bottom_group_one_one_one)
        Fabricate(Group::BottomGroup::Leader.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group: group2, person:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end

      it "counts multiple roles with separate types of the same person and same group as one" do
        item.dynamic_cost_parameters[:role_types] =
          [Group::BottomGroup::Leader.name, Group::BottomGroup::Member.name]
        Fabricate(Group::BottomGroup::Leader.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Member.name, group:, person:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end
    end

    context "with single person recipient" do
      let(:group) { groups(:bottom_group_one_one) }
      let(:recipient_person) { people(:bottom_member) }

      subject(:item) { described_class.for_people(recipient_person.id, **attrs) }

      before do
        item.invoice.recipient = recipient_person
      end

      it "counts matching roles" do
        expect(item.count).to eq(0)

        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)

        expect(item.recalculate.count).to eq(1)
      end

      it "ignores inactive role" do
        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.count).to eq(0)
      end

      it "ignores future role" do
        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.count).to eq(0)
      end

      it "considers past role which overlaps the period" do
        item.dynamic_cost_parameters[:period_start_on] = 11.months.ago
        item.dynamic_cost_parameters[:period_end_on] = 9.months.ago
        Fabricate(Group::BottomGroup::Leader.name, group:,
          person: recipient_person, start_on: 12.months.ago, end_on: 10.months.ago)
        expect(item.count).to eq(1)
      end

      it "ignores roles outside of the search group" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_two),
          person: recipient_person)
        expect(item.count).to eq(0)
      end

      it "searches deep within the group" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one),
          person: recipient_person)
        expect(item.count).to eq(1)
      end

      it "ignores role of the wrong type" do
        Fabricate(Group::BottomGroup::Member.name, group:, person: recipient_person)
        expect(item.count).to eq(0)
      end

      it "ignores roles which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient: recipient_person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(0)
      end

      it "ignores roles in subgroups which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one),
          person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient: recipient_person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(0)
      end

      it "counts roles even when subject with different id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient: recipient_person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id + 1,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient: recipient_person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different item_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient: recipient_person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id + 1)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient_id: recipient_person.id + 1, recipient_type: "Person", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts roles even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient_id: recipient_person.id, recipient_type: "Group", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts multiple roles of the same person and same group as one" do
        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end

      it "ignores roles of people other than recipient" do
        Fabricate(Group::BottomGroup::Leader.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end

      it "counts multiple roles of the same person in separate groups separately" do
        group2 = groups(:bottom_group_one_one_one)
        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group: group2, person: recipient_person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end

      it "counts multiple roles with separate types of the same person and same group as one" do
        item.dynamic_cost_parameters[:role_types] =
          [Group::BottomGroup::Leader.name, Group::BottomGroup::Member.name]
        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Member.name, group:, person: recipient_person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end
    end
  end

  context "#build_subjects" do
    let(:role_types) { [Group::BottomGroup::Leader.name] }

    before do
      Group::BottomGroup::Leader.destroy_all
    end

    context "with single group recipient" do
      let(:group) { groups(:bottom_layer_one) }
      let(:recipient_group) { groups(:bottom_group_one_one) }

      subject(:item) { described_class.for_groups(recipient_group.id, **attrs) }

      before do
        item.invoice.recipient = recipient_group
      end

      it "constructs attrs for creating ProcessedSubjects" do
        expect(item.subjects).to eq([])

        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        role2 = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        role3 = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        item.instance_variable_set(:@subjects, nil)

        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id},
          {subject_id: role2.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id},
          {subject_id: role3.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "ignores inactive role" do
        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.subjects).to eq([])
      end

      it "ignores future role" do
        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.subjects).to eq([])
      end

      it "considers past role which overlaps the period" do
        item.dynamic_cost_parameters[:period_start_on] = 11.months.ago
        item.dynamic_cost_parameters[:period_end_on] = 9.months.ago
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 12.months.ago, end_on: 10.months.ago)
        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "ignores roles outside of the recipient group" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_two))
        expect(item.subjects).to eq([])
      end

      it "searches deep within the group" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one))
        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "ignores role of the wrong type" do
        Fabricate(Group::BottomGroup::Member.name, group: recipient_group)
        expect(item.subjects).to eq([])
      end

      it "ignores roles which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient: recipient_group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to eq([])
      end

      it "ignores roles in subgroups which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one))
        previous_invoice = Fabricate(:invoice, recipient: recipient_group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to eq([])
      end

      it "counts roles even when subject with different id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient: recipient_group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id + 1,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to eq([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts roles even when subject with different type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient: recipient_group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to eq([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts roles even when subject with different item_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient: recipient_group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id + 1)

        expect(item.subjects).to eq([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts roles even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient_id: recipient_group.id + 1, recipient_type: "Group", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to eq([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts roles even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        previous_invoice = Fabricate(:invoice, recipient_id: recipient_group.id, recipient_type: "Person", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to eq([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "ignores group_id on the invoice" do
        group2 = groups(:bottom_group_one_two)
        item.invoice.group_id = group2.id
        Fabricate(Group::BottomGroup::Leader.name, group: group2)
        expect(item.subjects).to eq([])

        role = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group)
        item.instance_variable_set(:@subjects, nil)

        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts multiple roles of the same person and same group as one" do
        role1 = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group: recipient_group, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([
          {subject_id: role1.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts multiple roles of separate people separately" do
        role1 = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role2 = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([
          {subject_id: role1.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id},
          {subject_id: role2.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts multiple roles of the same person in separate groups separately" do
        group2 = groups(:bottom_group_one_one_one)
        role1 = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role2 = Fabricate(Group::BottomGroup::Leader.name, group: group2, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([
          {subject_id: role1.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id},
          {subject_id: role2.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts multiple roles with separate types of the same person and same group as one" do
        item.dynamic_cost_parameters[:role_types] =
          [Group::BottomGroup::Leader.name, Group::BottomGroup::Member.name]
        role1 = Fabricate(Group::BottomGroup::Leader.name, group: recipient_group,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Member.name, group: recipient_group, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([
          {subject_id: role1.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end
    end

    context "with single person recipient" do
      let(:group) { groups(:bottom_group_one_one) }
      let(:recipient_person) { people(:bottom_member) }

      subject(:item) { described_class.for_people(recipient_person.id, **attrs) }

      before do
        item.invoice.recipient = recipient_person
      end

      it "constructs attrs for creating ProcessedSubjects" do
        expect(item.subjects).to eq([])

        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        item.instance_variable_set(:@subjects, nil)

        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "ignores inactive role" do
        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.subjects).to eq([])
      end

      it "ignores future role" do
        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.subjects).to eq([])
      end

      it "considers past role which overlaps the period" do
        item.dynamic_cost_parameters[:period_start_on] = 11.months.ago
        item.dynamic_cost_parameters[:period_end_on] = 9.months.ago
        role = Fabricate(Group::BottomGroup::Leader.name, group:,
          person: recipient_person, start_on: 12.months.ago, end_on: 10.months.ago)
        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "ignores roles outside of the search group" do
        Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_two),
          person: recipient_person)
        expect(item.subjects).to eq([])
      end

      it "searches deep within the group" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one),
          person: recipient_person)
        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "ignores role of the wrong type" do
        Fabricate(Group::BottomGroup::Member.name, group:, person: recipient_person)
        expect(item.subjects).to eq([])
      end

      it "ignores roles which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient: recipient_person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to eq([])
      end

      it "ignores roles in subgroups which were processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one_one),
          person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient: recipient_person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to eq([])
      end

      it "counts roles even when subject with different id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient: recipient_person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id + 1,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts roles even when subject with different type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient: recipient_person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts roles even when subject with different item_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient: recipient_person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id + 1)

        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts roles even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient_id: recipient_person.id + 1, recipient_type: "Person", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts roles even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person)
        previous_invoice = Fabricate(:invoice, recipient_id: recipient_person.id, recipient_type: "Group", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          invoice_id: previous_invoice.id, item_id: template_item_id)

        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts multiple roles of the same person and same group as one" do
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "ignores roles of people other than recipient" do
        Fabricate(Group::BottomGroup::Leader.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts multiple roles of the same person in separate groups separately" do
        group2 = groups(:bottom_group_one_one_one)
        role1 = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role2 = Fabricate(Group::BottomGroup::Leader.name, group: group2, person: recipient_person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([
          {subject_id: role1.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id},
          {subject_id: role2.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end

      it "counts multiple roles with separate types of the same person and same group as one" do
        item.dynamic_cost_parameters[:role_types] =
          [Group::BottomGroup::Leader.name, Group::BottomGroup::Member.name]
        role = Fabricate(Group::BottomGroup::Leader.name, group:, person: recipient_person,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::BottomGroup::Member.name, group:, person: recipient_person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", item_id: 1337, invoice_id: item.invoice.id}
        ])
      end
    end
  end

  context "#dynamic_cost" do
    before do
      item.invoice.recipient = groups(:top_group)
    end

    it "multiplies price and count" do
      Fabricate(Group::TopGroup::Leader.name, group:)
      expect(item.dynamic_cost).to eq(21.00)
    end
  end
end
