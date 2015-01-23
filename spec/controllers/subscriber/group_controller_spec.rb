# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Subscriber::GroupController do


  before { sign_in(people(:top_leader)) }

  let(:list) { mailing_lists(:leaders) }
  let(:group) { list.group }

  context 'GET query' do
    subject { response.body }

    context 'top group' do
      before do
        get :query, q: 'bot', group_id: group.id, mailing_list_id: list.id
      end

      it { should =~ /Top \\u0026gt; Bottom One/ }
      it { should =~ /Bottom One \\u0026gt; Group 11/ }
      it { should =~ /Bottom One \\u0026gt; Group 12/ }
      it { should =~ /Top \\u0026gt; Bottom Two/ }
      it { should =~ /Bottom Two \\u0026gt; Group 21/ }
      it { should_not =~ /Bottom One \\u0026gt; Group 111/ }
    end

    context 'bottom layer' do
      let(:group) { groups(:bottom_layer_one) }
      let(:mailing_list) {  MailingList.create!(group: group, name: 'bottom_layer') }

      before do
        Group::BottomLayer::Leader.create!(group: group, person: people(:top_leader))
        get :query, q: 'bot', group_id: group.id, mailing_list_id: list.id
      end

      it 'does not include sister group or their descendants' do
        should =~ /Top \\u0026gt; Bottom One/
        should_not =~ /Top \\u0026gt; Bottom Two/
        should_not =~ /Bottom Two \\u0026gt; Group 21/
      end
    end

  end

  context 'GET roles.js' do
    it 'load role types' do
      xhr :get, :roles, group_id: group.id,
                        mailing_list_id: list.id,
                        subscription: { subscriber_id: groups(:bottom_layer_one) },
                        format: :js

      assigns(:role_types).root.should == Group::BottomLayer
    end

    it 'does not load role types for nil group' do
      xhr :get, :roles, group_id: group.id,
                        mailing_list_id: list.id,
                        format: :js

      assigns(:role_types).should be_nil
    end

  end

  context 'POST create' do
    it 'without subscriber_id replaces error' do
      post :create, group_id: group.id,
                    mailing_list_id: list.id

      should render_template('crud/new')
      assigns(:subscription).errors[:subscriber_id].should be_blank
      assigns(:subscription).errors[:subscriber_type].should be_blank
      assigns(:subscription).errors[:base].should have(1).item
    end

    it 'create subscription with role types' do
      expect do
        expect do
          post :create, group_id: group.id,
                        mailing_list_id: list.id,
                        subscription: { subscriber_id: groups(:bottom_layer_one),
                                        role_types: [Group::BottomLayer::Leader, Group::BottomGroup::Leader] }
        end.to change { Subscription.count }.by(1)
      end.to change { RelatedRoleType.count }.by(2)

      should redirect_to(group_mailing_list_subscriptions_path(group, list))
    end
  end

end
