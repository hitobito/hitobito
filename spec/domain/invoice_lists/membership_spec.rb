# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceLists::Membership do
  before do
    allow(Settings).to receive_message_chain(:invoices, :membership, :recipient, :roles).and_return(%w[
      Group::BottomLayer::Leader
      Group::BottomGroup::Leader
    ])
    allow(Settings).to receive_message_chain(:invoices, :membership, :recipient, :layer).and_return(Group::BottomLayer.sti_name)
  end

  describe "::warning" do
    subject(:warning) { InvoiceLists::Membership.warning }

    it "is nil if all groups have a configured recipient" do
      Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_two_one))
      expect(warning).to be_nil
    end

    it "lists groups where no recipient was found" do
      Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      expect(warning).to eq "Für folgende Gruppen konnte kein Empfänger ermittelt werden: Bottom Two"
    end
  end

  describe "::recipient_roles" do
    subject(:recipient_roles) { InvoiceLists::Membership.recipient_roles }

    it "is empty if no roles match" do
      expect(recipient_roles).to be_empty
    end

    it "finds layer leader" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      expect(recipient_roles).to eq([role])
    end

    it "finds group leader" do
      role = Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one))
      expect(recipient_roles).to eq([role])
    end

    it "finds preferred role if two roles match for different people in single layer" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one))
      expect(recipient_roles).to eq([role])
    end

    it "finds preferred role if two roles match for single person in layer" do
      preferred = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one), person: preferred.person)
      expect(recipient_roles).to eq([preferred])
    end

    it "finds two roles for single person if they are on distinct layers" do
      one = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      two = Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_two_one), person: one.person)
      expect(recipient_roles).to match_array([one, two])
    end
  end
end
