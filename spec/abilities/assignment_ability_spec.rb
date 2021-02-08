#  frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe AssignmentAbility do
  let(:top_group) { groups(:top_group) }
  let(:bottom_layer_two) { groups(:bottom_layer_two) }
  let(:user) { @role.person }
  let(:person) { people(:bottom_member) }
  let(:attachment) { messages(:letter) }
  let(:assignment_entry) do
    Assignment.create!(person: person,
                       creator: people(:top_leader),
                       attachment: attachment,
                       title: 'Example printing assignment',
                       description: 'please print this ok?')
  end

  subject { Ability.new(user.reload) }

  context :show do
    it 'may show when attachment can be shown' do
      @role = Fabricate('Group::TopGroup::Leader', group: top_group)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to be_able_to(:show, assignment_entry)
    end

    it 'may not show when attachment can not be shown' do
      @role = Fabricate('Group::BottomLayer::Member', group: bottom_layer_two)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to_not be_able_to(:show, assignment_entry)
    end
  end

  context :edit do
    it 'may edit when attachment can be edit' do
      @role = Fabricate('Group::TopGroup::Leader', group: top_group)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to be_able_to(:edit, assignment_entry)
    end

    it 'may not edit when attachment can not be edit' do
      @role = Fabricate('Group::BottomLayer::Member', group: bottom_layer_two)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to_not be_able_to(:edit, assignment_entry)
    end
  end

  context :update do
    it 'may update when attachment can be update' do
      @role = Fabricate('Group::TopGroup::Leader', group: top_group)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to be_able_to(:update, assignment_entry)
    end

    it 'may not update when attachment can not be update' do
      @role = Fabricate('Group::BottomLayer::Member', group: bottom_layer_two)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to_not be_able_to(:update, assignment_entry)
    end
  end

  context :new do
    let(:new_assignment) { Assignment.new(attachment: attachment) }

    it 'may allow new when attachment writeable' do
      @role = Fabricate('Group::TopGroup::Leader', group: top_group)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to be_able_to(:new, new_assignment)
    end

    it 'may not allow new when attachment not writeable' do
      @role = Fabricate('Group::BottomLayer::Member', group: bottom_layer_two)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to_not be_able_to(:new, new_assignment)
    end
  end

  context :create do
    it 'may allow create when attachment writeable' do
      @role = Fabricate('Group::TopGroup::Leader', group: top_group)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to be_able_to(:create, assignment_entry)
    end

    it 'may not allow create when attachment not writeable' do
      @role = Fabricate('Group::BottomLayer::Member', group: bottom_layer_two)
      Fabricate('Group::BottomLayer::Member', group: bottom_layer_two, person: user)

      is_expected.to_not be_able_to(:create, assignment_entry)
    end
  end
end
