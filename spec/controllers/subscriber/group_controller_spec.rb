# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Subscriber::GroupController do
  before { sign_in(people(:top_leader)) }

  let(:list) { mailing_lists(:leaders) }
  let(:group) { list.group }

  context "GET query" do
    subject { response.body }

    context "top group" do
      before do
        get :query, params: {q: "bot", group_id: group.id, mailing_list_id: list.id}
      end

      it { is_expected.to match(/Top \\u0026gt; Bottom One/) }
      it { is_expected.to match(/Bottom One \\u0026gt; Group 11/) }
      it { is_expected.to match(/Bottom One \\u0026gt; Group 12/) }
      it { is_expected.to match(/Top \\u0026gt; Bottom Two/) }
      it { is_expected.to match(/Bottom Two \\u0026gt; Group 21/) }
      it { is_expected.not_to match(/Bottom One \\u0026gt; Group 111/) }
    end

    context "bottom layer" do
      let(:group) { groups(:bottom_layer_one) }
      let(:list) { MailingList.create!(group: group, name: "bottom_layer") }

      before do
        Group::BottomLayer::Leader.create!(group: group, person: people(:top_leader))
        get :query, params: {q: "bot", group_id: group.id, mailing_list_id: list.id}
      end

      it "does not include sister group or their descendants" do
        is_expected.to match(/Top \\u0026gt; Bottom One/)
        is_expected.not_to match(/Top \\u0026gt; Bottom Two/)
        is_expected.not_to match(/Bottom Two \\u0026gt; Group 21/)
      end
    end
  end

  context "GET roles.js" do
    it "load role types" do
      get :roles, xhr: true, params: {
        group_id: group.id,
        mailing_list_id: list.id,
        subscription: {subscriber_id: groups(:bottom_layer_one)}
      }, format: :js

      expect(assigns(:role_types).root).to eq(Group::BottomLayer)
    end

    it "does not load role types for nil group" do
      get :roles, xhr: true, params: {
        group_id: group.id,
        mailing_list_id: list.id
      }, format: :js

      expect(assigns(:role_types)).to be_nil
    end
  end

  context "POST create" do
    it "without subscriber_id replaces error" do
      post :create, params: {
        group_id: group.id,
        mailing_list_id: list.id
      }

      is_expected.to render_template("crud/new")
      expect(assigns(:subscription).errors[:subscriber_id]).to be_blank
      expect(assigns(:subscription).errors[:subscriber_type]).to be_blank
      expect(assigns(:subscription).errors[:base].size).to eq(1)
    end

    it "create subscription with role types" do
      expect do
        expect do
          post :create, params: {
            group_id: group.id,
            mailing_list_id: list.id,
            subscription: {subscriber_id: groups(:bottom_layer_one),
                           role_types: [Group::BottomLayer::Leader, Group::BottomGroup::Leader]}
          }
        end.to change { Subscription.count }.by(1)
      end.to change { RelatedRoleType.count }.by(2)

      is_expected.to redirect_to(group_mailing_list_subscriptions_path(group, list))
    end
  end
end
