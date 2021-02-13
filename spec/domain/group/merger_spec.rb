# encoding: utf-8

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
        created_at: Date.today - 14, group: group1).person
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: group1)
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: group2)

      Fabricate(:event, groups: [group1])
      Fabricate(:event, groups: [group1])
      Fabricate(:event, groups: [group2])

      Fabricate(:invoice, group: group2, recipient: @person)
      Fabricate(:invoice_article, group: group2)
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
      expect(@person.reload.roles.only_deleted.count).to eq 1

      # last but not least, check nested set integrity
      expect(Group).to be_valid
    end

    it "should raise an error if one tries to merge two groups with different types/parent" do
      merge = Group::Merger.new(group1, other_group, "foo")
      expect { merge.merge! }.to raise_error(RuntimeError)
    end

    it "add events from both groups only once" do
      e = Fabricate(:event, groups: [group1, group2])
      merger.merge!

      e.reload
      expect(e.group_ids).to match_array([group1, group2, new_group].collect(&:id))
    end

    it "updates layer_group_id for descendants" do
      ids = (group1.descendants + group2.descendants).map(&:id)

      merger.merge!

      expect(Group.find(ids).map(&:layer_group_id).uniq).to eq [new_group.id]
    end

    it "moves invoices" do
      expect(group1.invoices.count).to eq 2
      expect(group2.invoices.count).to eq 1

      merger.merge!

      expect(new_group.invoices.count).to eq 3
    end

    it "moves invoice-articles" do
      expect(group1.invoice_articles.count).to eq 3
      expect(group2.invoice_articles.count).to eq 1

      merger.merge!

      expect(new_group.invoice_articles.count).to eq 4
    end
  end
end
