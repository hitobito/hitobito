# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe JsonApi::ContactAbility do

  let(:group) { groups(:bottom_layer_one) }
  let(:person) { Fabricate(:person) }
  let!(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group, person: person) }
  let(:phone_number) { Fabricate(:phone_number, contactable: person) }

  let(:main_ability) { Ability.new(user) }
  let(:user) { Fabricate(:person) }

  subject { JsonApi::ContactAbility.new(main_ability) }

  context 'when having `show_details` permission on contactable' do
    let!(:user_role) { Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: group, person: user) }

    it 'may read public phone_numbers' do
      phone_number.public = true
      is_expected.to be_able_to(:read, phone_number)
    end

    it 'may read non-public phone_numbers' do
      phone_number.public = false
      is_expected.to be_able_to(:read, phone_number)
    end
  end

  context 'when having `show` permission on contactable' do
    let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two), person: user) }

    it 'may read public phone_numbers' do
      phone_number.public = true
      is_expected.to be_able_to(:read, phone_number)
    end

    it 'may not read non-public phone_numbers' do
      phone_number.public = false
      is_expected.not_to be_able_to(:read, phone_number)
    end
  end

  context 'without any permission on contactable' do
    let!(:user_role) { Fabricate(Role::External.name.to_sym, group: group, person: user) }

    it 'may not read non-public phone_numbers' do
      phone_number.public = false
      is_expected.not_to be_able_to(:read, phone_number)
    end

    it 'may not read public phone_numbers' do
      phone_number.public = true
      is_expected.not_to be_able_to(:read, phone_number)
    end
  end
end
