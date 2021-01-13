#  frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe MessageAbility do

  let(:user) { role.person }
  let(:group) { role.group }
  let(:list) { Fabricate(:mailing_list, group: group) }
  let(:message) { list.messages.build }
  let(:actions) { [:create, :update, :destroy] }

  subject { Ability.new(user.reload) }

  context 'layer and below full' do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    context 'in own group' do
      it 'may manage messages' do
        actions.each do |action|
          is_expected.to be_able_to(action, message)
        end
      end
    end

    context 'in group in same layer' do
      let(:group) { groups(:top_layer) }
      it 'may manage messages' do
        actions.each do |action|
          is_expected.to be_able_to(action, message)
        end
      end
    end

    context 'in global group in same layer' do
      let(:group) { groups(:toppers) }

      it 'may manage messages' do
        actions.each do |action|
          is_expected.to be_able_to(action, message)
        end
      end
    end

    context 'in group in lower layer' do
      let(:group) { groups(:bottom_layer_one) }

      it 'may manage messages' do
        actions.each do |action|
          is_expected.to be_able_to(action, message)
        end
      end
    end

    context 'in group in upper layer' do
      let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }
      let(:group) { groups(:top_layer) }

      it 'may not manage messages' do
        actions.each do |action|
          is_expected.not_to be_able_to(action, message)
        end
      end
    end
  end
end
