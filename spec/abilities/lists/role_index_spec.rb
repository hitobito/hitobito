# frozen_string_literal: true

#  Copyright (c) 2023-2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Role.accessible_by(ability, :index)" do
  let(:group) { groups(:top_group) }
  let(:person) { Fabricate(:person) }
  let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: group, person: person) }

  let(:user) { Fabricate(:person) }

  subject { Ability.new(user) }

  context "when having `show_full` permission on person" do
    let!(:user_role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: group, person: user) }

    it do
      is_expected.to be_able_to(:index, role)
      expect(Role.accessible_by(subject, :index)).to include(role)
    end
  end

  context "when missing `show_full` permission on person" do
    let!(:user_role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group, person: user) }

    it do
      is_expected.not_to be_able_to(:index, role)
      expect(Role.accessible_by(subject, :index)).not_to include(role)
    end
  end
end
