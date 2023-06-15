# frozen_string_literal: true

#  Copyright (c) 2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Roles::AssignLastActiveRoleJob do
  let(:job) { described_class.new }
  let(:group)         { groups(:top_layer) }
  let(:person)        { role.person.reload }
  let(:role) do
    Fabricate(Group::TopLayer::TopAdmin.name, group: group,
              created_at: Time.zone.now - 1.year)
  end

  let(:child_group)      { groups(:bottom_layer_one) }
  let(:child_group_one)  { groups(:bottom_group_one_one) }
  let(:child_person)     { child_role.person.reload }
  let(:child_role) do
    Fabricate(Group::BottomGroup::Leader.name, group: child_group_one,
              created_at: Time.zone.now - 1.year)
  end

  context 'last active role' do
    it 'gets assigned' do
      role.update_column(:deleted_at, 1.week.ago)
      child_role.update_column(:deleted_at, 1.week.ago)
      expect(person.last_active_role).to eq(nil)
      expect(child_person.last_active_role).to eq(nil)

      job.perform

      person.reload
      child_person.reload
      expect(person.last_active_role).to eq(role)
      expect(child_person.last_active_role).to eq(child_role)
    end

    it 'gets assigned last deleted role' do
      last_deleted_role = Fabricate(Group::TopLayer::TopAdmin.name, group: group, person: person,
                                    created_at: Time.zone.now - 1.year, deleted_at: 1.week.ago)
      role.update_column(:deleted_at, 2.weeks.ago)
      expect(person.last_active_role).to eq(nil)

      job.perform

      person.reload
      expect(person.last_active_role).to eq(last_deleted_role)
    end

    it 'gets removed' do
      role.update_column(:deleted_at, 1.week.ago)
      child_role.update_column(:deleted_at, 1.week.ago)
      person.update_column(:last_active_role_id, role.id)
      child_person.update_column(:last_active_role_id, child_role.id)
      expect(person.last_active_role).to eq(role)
      expect(child_person.last_active_role).to eq(child_role)

      Fabricate(Group::TopLayer::TopAdmin.name, group: group, person: person,
                created_at: 1.day.ago)
      Fabricate(Group::BottomGroup::Leader.name, group: child_group_one, person: child_person,
                created_at: 1.day.ago)

      job.perform

      person.reload
      child_person.reload
      expect(person.last_active_role).to eq(nil)
      expect(child_person.last_active_role).to eq(nil)
    end
  end

end
