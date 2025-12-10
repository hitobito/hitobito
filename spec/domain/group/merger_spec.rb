#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::Merger do
  let(:group1) { groups(:bottom_layer_one) }
  let(:group2) { groups(:bottom_layer_two) }
  let(:other_group) { groups(:top_layer) }

  let(:merger) { Group::Merger.new(group1, group2, "foo") }

  let(:new_group) { Group.find(merger.new_group.id) }

  context "merge groups" do
    before do
      @person = Fabricate(Group::BottomLayer::Member.name.to_sym,
        created_at: Time.zone.today - 14, group: group1).person
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: group1)
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: group2)

      Fabricate(:event, groups: [group1])
      Fabricate(:event, groups: [group1])
      Fabricate(:event, groups: [group2])

      Fabricate(:invoice, group: group2, recipient: @person)
      Fabricate(:invoice_article, group: group2)
      InvoiceRun.create!(title: "Rechnungslauf", group_id: group2.id)
    end

    it "creates a new group and merges roles, events" do
      expect(merger.group2_valid?).to eq true
      merger.merge!

      expect(new_group.name).to eq "foo"
      expect(new_group.type).to eq merger.new_group.type

      expect(new_group.children.count).to eq 3

      expect(new_group.events.count).to eq 3

      expect(new_group.roles.count).to eq 4

      # recent groups
      expect { Group.without_deleted.find(group1.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { Group.without_deleted.find(group2.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(group1.children.count).to eq 0
      expect(group2.children.count).to eq 0
      expect(group1.roles.count).to eq 0
      expect(group2.roles.count).to eq 0
      expect(group1.events.count).to eq 2
      expect(group2.events.count).to eq 1

      # the recent role should have been soft-deleted
      expect(@person.reload.roles.ended.count).to eq 1

      # last but not least, check nested set integrity
      expect(Group).to be_valid
    end

    it "should raise an error if one tries to merge two groups with different types/parent" do
      merge = Group::Merger.new(group1, other_group, "foo")
      expect { merge.merge! }.to raise_error(RuntimeError)
    end

    it "handles invalid merged groups" do
      outdated_contact = people(:bottom_member)
      outdated_contact.roles.destroy_all

      group1.update_attribute(:contact_id, outdated_contact.id)
      expect(group1).not_to be_valid

      group1.children[0].update_attribute(:contact_id, outdated_contact.id)
      expect(group1.children[0]).not_to be_valid

      group1.children[0].children[0].update_attribute(:contact_id, outdated_contact.id)
      expect(group1.children[0].children[0]).not_to be_valid

      merger.merge!

      expect(new_group.children.count).to eq 3
    end

    it "handles invalid roles" do
      group1.roles[0].update_attribute(:start_on, "2200-06-11")
      group1.roles[0].update_attribute(:end_on, "2200-06-10")
      expect(group1.roles[0]).not_to be_valid

      child_role = Fabricate(Group::BottomGroup::Leader.name.to_sym,
        group: group2.children[0],
        person: people(:bottom_member))
      child_role.update_attribute(:start_on, "2200-06-11")
      child_role.update_attribute(:end_on, "2200-06-10")
      expect(child_role).not_to be_valid

      merger.merge!

      expect(new_group.roles.count).to eq 4
    end

    it "handles archived subgroups with archived roles" do
      Fabricate(Group::BottomGroup::Leader.name.to_sym,
        group: group1.children[0],
        person: people(:bottom_member))
      group1.children[0].archive!
      expect(group1.children[0]).to be_archived
      expect(group1.children[0].roles[0]).to be_archived

      merger.merge!

      expect(new_group.children.count).to eq 3
      expect(new_group.children[0]).to be_archived
      expect(new_group.children[0].roles[0]).to be_archived
    end

    it "handles deleted subgroups" do
      group1.children[0].update_attribute(:deleted_at, 1.day.ago)
      expect(group1.children[0]).to be_deleted

      merger.merge!

      expect(new_group.children.count).to eq 3
      expect(new_group.children[0]).to be_deleted
    end

    it "does not merge archived group" do
      group2.archive!
      expect(group2).to be_archived
      expect(group2.roles[0]).to be_archived

      expect { merger.merge! }.to raise_error(RuntimeError)
    end

    it "does not merge deleted group" do
      group2.update_attribute(:deleted_at, 1.day.ago)
      expect(group2).to be_deleted

      expect { merger.merge! }.to raise_error(RuntimeError)
    end

    it "add events from both groups only once" do
      e = Fabricate(:event, groups: [group1, group2])
      merger.merge!

      e.reload
      expect(e.group_ids).to match_array([group1, group2, new_group].collect(&:id))
    end

    it "handles invalid events" do
      group1.events[0].update_attribute(:application_closing_at, "2025-06-10")
      group1.events[0].update_attribute(:application_opening_at, "2025-06-11")
      expect(group1.events[0]).not_to be_valid

      invalid_serialized_column = %w[street zip_code town foobar]
      group2.events[0].update_attribute(:required_contact_attrs, invalid_serialized_column)
      expect(group2.events[0]).not_to be_valid

      child_event = Fabricate(:event, groups: [group1])
      child_event.update_attribute(:required_contact_attrs, invalid_serialized_column)
      expect(child_event).not_to be_valid

      merger.merge!

      expect(new_group.events.count).to eq 3
    end

    it "updates layer_group_id for descendants" do
      ids = (group1.descendants + group2.descendants).map(&:id)

      merger.merge!

      expect(Group.find(ids).map(&:layer_group_id).uniq).to eq [new_group.id]
    end

    it "moves invoices" do
      expect(group1.issued_invoices.count).to eq 2
      expect(group2.issued_invoices.count).to eq 1

      merger.merge!

      expect(new_group.issued_invoices.count).to eq 3
    end

    it "moves even invalid invoices" do
      expect(group1.issued_invoices.count).to eq 2
      expect(group2.issued_invoices.count).to eq 1
      group1.issued_invoices[0].update_attribute(:state, "foobar")
      expect(group1.issued_invoices[0]).not_to be_valid

      merger.merge!

      expect(new_group.issued_invoices.count).to eq 3
    end

    it "moves invoice-articles" do
      expect(group1.invoice_articles.count).to eq 3
      expect(group2.invoice_articles.count).to eq 1

      merger.merge!

      expect(new_group.invoice_articles.count).to eq 4
    end

    it "moves even invalid invoice-articles" do
      expect(group1.invoice_articles.count).to eq 3
      expect(group2.invoice_articles.count).to eq 1
      group1.invoice_articles[0].update_attribute(:number, nil)
      expect(group1.invoice_articles[0]).not_to be_valid

      merger.merge!

      expect(new_group.invoice_articles.count).to eq 4
    end

    it "moves invoice runs" do
      expect(group1.invoice_runs.count).to eq 0
      expect(group2.invoice_runs.count).to eq 1

      merger.merge!

      expect(new_group.invoice_runs.count).to eq 1
    end

    it "moves even invalid invoice runs" do
      expect(group1.invoice_runs.count).to eq 0
      expect(group2.invoice_runs.count).to eq 1
      group2.invoice_runs[0].update_attribute(:receiver_type, "foobar")
      expect(group2.invoice_runs[0]).not_to be_valid

      merger.merge!

      expect(new_group.invoice_runs.count).to eq 1
    end
  end
end
