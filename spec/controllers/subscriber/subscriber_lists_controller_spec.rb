# frozen_string_literal: true

#  Copyright (c) 2023, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Subscriber::SubscriberListsController do
  before { sign_in(person) }

  let(:list) { Fabricate(:mailing_list, group: group, subscribable_for: :anyone) }
  let(:group) { groups(:top_group) }
  let(:member_ids) { @members.map(&:id).join(",") }

  before do
    @members = (0...10).map do
      Fabricate(:"Group::TopGroup::LocalSecretary", group: group).person
    end
  end

  context "POST create" do
    context "unauthorized" do
      let(:person) { people(:bottom_member) }

      it "is unauthorized for mailing list without create subscription permission" do
        expect do
          post :create,
            params: {group_id: group.id, mailing_list_id: list.id, ids: member_ids}
        end.to raise_error(CanCan::AccessDenied)
      end

      context "for non-accessible members" do
        let(:person) { Fabricate(:"Group::BottomLayer::Leader", group: groups(:bottom_layer_one)).person }
        let(:list) { Fabricate(:mailing_list, group: groups(:bottom_layer_one), subscribable_for: :anyone) }

        it "does nothing for authorized mailing list" do
          expect do
            post :create,
              params: {group_id: group.id, mailing_list_id: list.id, ids: member_ids}
            expect(response).to redirect_to(group_people_path(group))
          end.to change { Subscription.count }.by(0)
        end
      end
    end

    context "authorized" do
      let(:person) { people(:top_leader) }

      it "creates multiple person subscriptions for given ids" do
        expect do
          post :create,
            params: {group_id: group.id, mailing_list_id: list.id, ids: member_ids}
          expect(response).to redirect_to(group_people_path(group))
        end.to change { Subscription.count }.by(10)

        @members.each do |member|
          expect(list.subscribed?(member)).to eq(true)
        end
      end

      it "ignores person with existing subscription" do
        subscription_1 = Subscription.create!(subscriber: @members.first, mailing_list: list)
        subscription_2 = Subscription.create!(subscriber: @members.second, mailing_list: list)

        expect do
          post :create,
            params: {group_id: group.id, mailing_list_id: list.id, ids: member_ids}
          expect(response).to redirect_to(group_people_path(group))
        end.to change { Subscription.count }.by(8)

        expect(Subscription.where(subscriber: subscription_1.subscriber,
          mailing_list: subscription_1.mailing_list).count).to eq(1)
        expect(Subscription.where(subscriber: subscription_2.subscriber,
          mailing_list: subscription_2.mailing_list).count).to eq(1)

        @members.each do |member|
          expect(list.subscribed?(member)).to eq(true)
        end
      end
    end
  end
end
