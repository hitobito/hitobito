# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::UpdateAfterRoleChange do
  let(:person) { Fabricate(:person) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_group) { groups(:bottom_group_one_one) }

  describe "contact data visible" do
    it "updates to true if any role has contact_data permission" do
      expect {
        Fabricate(Group::TopGroup::Leader.sti_name, group: top_group, person: person)
      }.to change { person.reload.contact_data_visible }.from(false).to(true)
      expect {
        Fabricate(Group::TopGroup::LocalGuide.sti_name, group: top_group, person: person)
      }.not_to change { person.reload.contact_data_visible }
    end

    it "updates to false if sole role with contact_data permission expires" do
      role = Fabricate(Group::TopGroup::Leader.sti_name, group: top_group, person: person)
      expect(person.reload.contact_data_visible).to eq true
      expect {
        role.reload.update!(start_on: 2.days.ago, end_on: 1.day.ago)
        described_class.new(person.reload).set_contact_data_visible
      }.to change { person.reload.contact_data_visible }.from(true).to(false)
    end

    it "updates to false if sole role with contact_data permission is destroyed" do
      role = Fabricate(Group::TopGroup::Leader.sti_name, group: top_group, person: person)
      expect(person.reload.contact_data_visible).to eq true
      expect {
        role.destroy
      }.to change { person.reload.contact_data_visible }.from(true).to(false)
    end
  end

  describe "primary_group_id" do
    it "updates if primary_group_id is blank" do
      expect {
        Fabricate(Group::TopGroup::Leader.sti_name, group: top_group, person: person)
      }.to change { person.reload.primary_group_id }.from(nil).to(top_group.id)
    end

    it "does not change if role in a another group is created" do
      Fabricate(Group::TopGroup::Leader.sti_name, group: top_group, person: person)
      expect {
        Fabricate(Group::BottomGroup::Leader.sti_name, group: bottom_group, person: person)
      }.not_to change { person.reload.primary_group_id }
    end

    it "does change if last role in primary_group is destroyed" do
      role = Fabricate(Group::TopGroup::Leader.sti_name, group: top_group, person: person)
      Fabricate(Group::BottomGroup::Leader.sti_name, group: bottom_group, person: person)
      expect {
        role.destroy
      }.to change { person.reload.primary_group_id }.from(top_group.id).to(bottom_group.id)
    end
  end
end
