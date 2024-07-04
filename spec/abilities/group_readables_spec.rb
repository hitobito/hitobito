# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito= and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe GroupReadables do
  let(:user) { Fabricate(:person) }
  let(:ability) { GroupReadables.new(user) }

  subject(:accessible_groups) { Group.accessible_by(ability, :index) }

  context "with any role" do
    before { Fabricate(Role::External.sti_name, person: user, group: groups(:toppers)) }

    it "can index all groups" do
      is_expected.to match_array(Group.all)
    end
  end

  context "without any role" do
    it "cannot index any group" do
      expect(user.roles).to be_empty
      is_expected.to be_empty
    end
  end

  context "as root user" do
    let(:user) { people(:root) }

    it "can index all groups" do
      is_expected.to match_array(Group.all)
    end
  end
end
