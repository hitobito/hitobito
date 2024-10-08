# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::UpdateAfterRoleChangeJob do
  let(:root) { people(:root) }
  let(:person) { people(:top_leader) }
  let(:updater) { instance_double(People::UpdateAfterRoleChange) }
  let(:role) { roles(:top_leader) }
  let(:bottom_layer) { groups(:bottom_layer_one) }

  subject(:job) { described_class.new }

  describe "primary_group_id" do
    it "does not change if matches active role" do
      job.perform
      expect(person.reload.primary_group_id).to eq role.group_id
    end

    it "does not change if new role is created in another group" do
      Fabricate(Group::BottomLayer::Member.sti_name, person: person, group: bottom_layer)
      job.perform
      expect(person.reload.primary_group_id).to eq role.group_id
    end

    it "does change to nil if role expired" do
      role.update_columns(start_on: 3.days.ago, end_on: 1.day.ago)
      job.perform

      expect(person.reload.primary_group_id).to be_nil
    end

    it "does change from nil to group_id of role becoming active" do
      person.update_columns(primary_group_id: nil)
      role.update_columns(start_on: Time.zone.today, end_on: 1.day.from_now)
      job.perform

      expect(person.reload.primary_group_id).to eq role.group_id
    end

    it "does change from invalid to active role group_id" do
      person.update_columns(primary_group_id: -1)
      job.perform
      expect(person.reload.primary_group_id).to eq role.group_id
    end

    it "does change from invalid to nil if no role is active" do
      role.delete
      person.update_columns(primary_group_id: -1)
      job.perform
      expect(person.reload.primary_group_id).to be_nil
    end

    it "exludes root user" do
      root.update(primary_group_id: -1)
      job.perform
      expect(root.reload.primary_group_id).to eq(-1)
    end
  end

  describe "contact_data_visible" do
    it "does not change to if matches active role" do
      job.perform
      expect(person.reload.contact_data_visible).to eq true
    end

    it "does not change if new role without contact data is created" do
      Fabricate(Group::BottomLayer::Member.sti_name, person: person, group: bottom_layer)
      expect(person.reload.contact_data_visible).to eq true
    end

    it "does change to false if role expired" do
      role.update_columns(end_on: Time.zone.yesterday)
      job.perform
      expect(person.reload.contact_data_visible).to eq false
    end

    it "does change to true if becomes active" do
      person.update_columns(contact_data_visible: false)
      role.update_columns(start_on: Time.zone.yesterday)
      job.perform
      expect(person.reload.contact_data_visible).to eq true
    end

    it "exludes root user" do
      root.update(contact_data_visible: true)
      job.perform
      expect(root.reload.contact_data_visible).to eq(true)
    end
  end
end
