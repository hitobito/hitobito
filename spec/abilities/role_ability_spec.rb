# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe RoleAbility do
  subject(:ability) { Ability.new(people(:top_leader)) }

  it "may build a new role without type in a group of the layer" do
    is_expected.to be_able_to(:create, Role.new(group: groups(:top_group)))
  end

  it "may not create restricted roles" do
    allow(Group::TopGroup::Member).to receive(:kind).and_return(nil)

    is_expected.not_to be_able_to(:create, Group::TopGroup::Member.new(group: groups(:top_group)))
    is_expected.to be_able_to(:create, Group::TopGroup::Leader.new(group: groups(:top_group)))
  end

  it "lists the roles of fully readable people" do
    role = Fabricate(Group::BottomLayer::Member.sti_name, group: groups(:bottom_layer_one))

    expect(Role.accessible_by(ability, :index)).to include(role)
    expect(Role.accessible_by(Ability.new(people(:bottom_member)), :index))
      .not_to include(roles(:top_leader))
  end
end
