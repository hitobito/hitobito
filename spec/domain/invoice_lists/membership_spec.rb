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

  xdescribe "::warning" do
    subject(:warning) { InvoiceLists::Membership.warning }

    it "is nil " do
      expect(warning).to eq ""
    end

    it "is present if there is a mismatch between group and roles" do
      expect(warning).to eq ""
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

    it "finds role only once if both roles match" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one), person: role.person)
      expect(recipient_roles).to eq([role])
    end

    it "finds role twice two roles match but on distinct layers" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_two_one), person: role.person)
      expect(recipient_roles).to eq([role, role])
    end

    it "finds prefered role role if two roles match for layer" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one))
      expect(recipient_roles).to eq([role])
    end
  end
end
