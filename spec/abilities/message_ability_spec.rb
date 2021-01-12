# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MessageAbility do

  let(:user) { @role.person }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_layer_one) { groups(:bottom_layer_one) }

  subject { Ability.new(user.reload) }

  context :index do
    it 'may list messages if mailinglist writable' do
      @role = Fabricate('Group::BottomLayer::Leader', group: bottom_layer_one)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to be_able_to(:index, duplicate_entry)
    end

    it 'may not list messages if mailinglist not writable' do
      @role = Fabricate('Group::BottomLayer::Member', group: bottom_layer_one)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.not_to be_able_to(:merge, duplicate_entry)
    end
  end
end
