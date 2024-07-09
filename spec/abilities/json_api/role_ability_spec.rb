# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JsonApi::RoleAbility do
  let(:group) { groups(:top_group) }
  let(:person) { Fabricate(:person) }
  let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: group, person: person) }

  let(:main_ability) { Ability.new(user) }
  let(:user) { Fabricate(:person) }

  subject { JsonApi::RoleAbility.new(main_ability) }

  context "when having `show_full` permission on person" do
    let!(:user_role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: group, person: user) }

    it do
      is_expected.to be_able_to(:read, role)
    end
  end

  context "when missing `show_full` permission on person" do
    let!(:user_role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group, person: user) }

    it { is_expected.not_to be_able_to(:read, role) }
  end
end
