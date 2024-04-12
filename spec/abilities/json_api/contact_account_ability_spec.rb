# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe JsonApi::ContactAccountAbility do
  subject { JsonApi::ContactAccountAbility.new(main_ability) }
  let(:main_ability) { Ability.new(user) }
  let(:user) { Fabricate(:person) }
  let(:group) { groups(:bottom_layer_one) }

  context 'Person contactable' do
    let(:person) { Fabricate(:person) }
    let!(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group, person: person) }
    let(:phone_number) { Fabricate(:phone_number, contactable: person) }

    context 'when having `show_details` permission on contactable' do
      before do
        Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: group, person: user)
        expect(main_ability).to be_able_to(:show_details, person)
      end

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
      before do
        Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two), person: user)
        expect(main_ability).to be_able_to(:show, person)
        expect(main_ability).not_to be_able_to(:show_details, person)
      end

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
      before do
        Fabricate(Role::External.name.to_sym, group: group, person: user)
        expect(main_ability).not_to be_able_to(:show, person)
        expect(main_ability).not_to be_able_to(:show_details, person)
      end

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

  context 'Group contactable' do
    let(:contact_account) { Fabricate(:phone_number, contactable: group) }

    context 'when having `read` permission on contactable' do
      let(:group) { groups(:top_group)}

      before do
        Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_one), person: user)
        expect(main_ability).to be_able_to(:read, group)
        expect(main_ability).not_to be_able_to(:show_details, group)
      end

      it 'may read public phone_numbers' do
        contact_account.public = true
        is_expected.to be_able_to(:read, contact_account)
      end

      it 'may not read non-public phone_numbers' do
        contact_account.public = false
        is_expected.not_to be_able_to(:read, contact_account)
      end
    end

    context 'when having `show_details` permission on contactable' do
      before do
        Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group, person: user)
        expect(main_ability).to be_able_to(:show_details, group)
      end

      it 'may read public phone_numbers' do
        contact_account.public = true
        is_expected.to be_able_to(:read, contact_account)
      end

      it 'may not read non-public phone_numbers' do
        contact_account.public = false
        is_expected.to be_able_to(:read, contact_account)
      end
    end

    context 'without any permission on contactable' do
      before do
        expect(main_ability).not_to be_able_to(:read, group)
      end

      it 'may not read public phone_numbers' do
        contact_account.public = true
        is_expected.not_to be_able_to(:read, contact_account)
      end

      it 'may not read non-public phone_numbers' do
        contact_account.public = false
        is_expected.not_to be_able_to(:read, contact_account)
      end
    end
  end
end
