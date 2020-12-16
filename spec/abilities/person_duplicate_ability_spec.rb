# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PersonDuplicateAbility do

  let(:user) { @role.person }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_layer_one) { groups(:bottom_layer_one) }
  let(:bottom_layer_two) { groups(:bottom_layer_two) }
  let(:person_1) { Fabricate('Group::BottomGroup::Member', group: groups(:bottom_group_one_one)).person }
  let(:person_2) { Fabricate('Group::BottomGroup::Member', group: groups(:bottom_group_two_one)).person }
  let(:duplicate_entry) do
    PersonDuplicate.create!(
      person_1: person_1,
      person_2: person_2
    )
  end

  subject { Ability.new(user.reload) }

  context :merge do
    it 'may merge if at least one person readable / one writable' do
      @role = Fabricate('Group::BottomLayer::Leader', group: bottom_layer_one)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to be_able_to(:merge, duplicate_entry)
    end

    it 'may not merge if both persons are readable only' do
      @role = Fabricate('Group::BottomLayer::Member', group: bottom_layer_one)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.not_to be_able_to(:merge, duplicate_entry)
    end

    it 'may not merge if one person is not readable' do
      @role = Fabricate('Group::BottomLayer::Member', group: bottom_layer_one)

      is_expected.not_to be_able_to(:merge, duplicate_entry)
    end
  end

  context :ignore do
    it 'may ignore if at least one person readable / one writable' do
      @role = Fabricate('Group::BottomLayer::Leader', group: bottom_layer_one)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to be_able_to(:ignore, duplicate_entry)
    end

    it 'may not ignore if both persons are readable only' do
      @role = Fabricate('Group::BottomLayer::Member', group: bottom_layer_one)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.not_to be_able_to(:ignore, duplicate_entry)
    end

    it 'may not ignore if one person is not readable' do
      @role = Fabricate('Group::BottomLayer::Member', group: bottom_layer_one)

      is_expected.not_to be_able_to(:ignore, duplicate_entry)
    end
  end
end
