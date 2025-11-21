# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceRuns::Receivers do
  let(:config) { Settings.invoice_runs.fixed_fees.membership.receivers }
  let(:top_leader) { roles(:top_leader) }

  subject(:receivers) { described_class.new(config) }

  describe "roles" do
    let(:people_ids) { receivers.roles.map(&:person_id) }

    it "is empty if no roles match" do
      expect(people_ids).to be_empty
    end

    it "finds layer leader" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      expect(people_ids).to eq([role.person_id])
    end

    it "finds group leader" do
      role = Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one))
      expect(people_ids).to eq([role.person_id])
    end

    it "finds preferred role if two roles match for different people in single layer" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one))
      expect(people_ids).to eq([role.person_id])
    end

    it "finds preferred role if two roles match for single person in layer" do
      preferred = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one), person: preferred.person)
      expect(people_ids).to eq([preferred.person_id])
    end

    it "finds two roles for single person if they are on distinct layers" do
      one = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      two = Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_two_one), person: one.person)
      expect(people_ids).to match_array([one, two].map(&:person_id))
    end
  end

  describe "build" do
    it "builds receiver object with id and layer_group_id" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      receiver = receivers.build.first
      expect(receiver.id).to eq role.person_id
      expect(receiver.layer_group_id).to eq role.group.layer_group_id
    end
  end
end
