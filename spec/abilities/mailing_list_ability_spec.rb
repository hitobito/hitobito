# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingListAbility do

  let(:user) { role.person }
  let(:group) { role.group }
  let(:list) { Fabricate(:mailing_list, group: group) }

  subject { Ability.new(user.reload) }

  context 'layer and below full' do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    context 'in own group' do
      it 'may show mailing lists' do
        should be_able_to(:show, list)
      end

      it 'may update mailing lists' do
        should be_able_to(:update, list)
      end

      it 'may index subscriptions' do
        should be_able_to(:index_subscriptions, list)
      end

      it 'may create subscriptions' do
        should be_able_to(:create, list.subscriptions.new)
      end
    end

    context 'in group in same layer' do
      let(:group) { groups(:toppers) }

      it 'may show mailing lists' do
        should be_able_to(:show, list)
      end

      it 'may update mailing lists' do
        should be_able_to(:update, list)
      end

      it 'may index subscriptions' do
        should be_able_to(:index_subscriptions, list)
      end

      it 'may create subscriptions' do
        should be_able_to(:create, list.subscriptions.new)
      end
    end

    context 'in group in lower layer' do
      let(:group) { groups(:bottom_layer_one) }

      it 'may show mailing lists' do
        should be_able_to(:show, list)
      end

      it 'may not update mailing lists' do
        should_not be_able_to(:update, list)
      end

      it 'may not index subscriptions' do
        should_not be_able_to(:index_subscriptions, list)
      end

      it 'may not create subscriptions' do
        should_not be_able_to(:create, list.subscriptions.new)
      end
    end

    context 'in group in upper layer' do
      let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }
      let(:group) { groups(:top_layer) }

      it 'may show mailing lists' do
        should be_able_to(:show, list)
      end

      it 'may not update mailing lists' do
        should_not be_able_to(:update, list)
      end

      it 'may not index subscriptions' do
        should_not be_able_to(:index_subscriptions, list)
      end

      it 'may not create subscriptions' do
        should_not be_able_to(:create, list.subscriptions.new)
      end
    end
  end

  context 'group full' do
    let(:role) { Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers)) }

    context 'in own group' do
      it 'may show mailing lists' do
        should be_able_to(:show, list)
      end

      it 'may update mailing lists' do
        should be_able_to(:update, list)
      end

      it 'may index subscriptions' do
        should be_able_to(:index_subscriptions, list)
      end

      it 'may create subscriptions' do
        should be_able_to(:create, list.subscriptions.new)
      end
    end

    context 'in group in same layer' do
      let(:group) { groups(:top_group) }

      it 'may show mailing lists' do
        should be_able_to(:show, list)
      end

      it 'may not update mailing lists' do
        should_not be_able_to(:update, list)
      end

      it 'may not index subscriptions' do
        should_not be_able_to(:index_subscriptions, list)
      end

      it 'may not create subscriptions' do
        should_not be_able_to(:create, list.subscriptions.new)
      end
    end

    context 'in group in lower layer' do
      let(:group) { groups(:bottom_layer_one) }

      it 'may show mailing lists' do
        should be_able_to(:show, list)
      end

      it 'may not update mailing lists' do
        should_not be_able_to(:update, list)
      end

      it 'may not index subscriptions' do
        should_not be_able_to(:index_subscriptions, list)
      end

      it 'may not create subscriptions' do
        should_not be_able_to(:create, list.subscriptions.new)
      end
    end

    context 'for destroyed group' do
      let(:group) { groups(:bottom_group_two_one) }

      before { list; groups(:toppers).destroy }

      it 'may not create mailing list' do
        should_not be_able_to(:create, list)
      end

      it 'may not update mailing list' do
        should_not be_able_to(:update, list)
      end

      it 'may not create subscription' do
        should_not be_able_to(:create, list.subscriptions.new)
      end
    end
  end
end
