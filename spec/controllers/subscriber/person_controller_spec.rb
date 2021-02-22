#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Subscriber::PersonController do
  before { sign_in(user) }

  let(:group) { groups(:top_group) }
  let(:user) { people(:top_leader) }
  let(:list) { Fabricate(:mailing_list, group: group) }

  context "POST create" do
    it "without subscriber_id replaces error" do
      post :create, params: {
        group_id: group.id,
        mailing_list_id: list.id,
      }

      is_expected.to render_template("crud/new")
      expect(assigns(:subscription).errors.size).to eq(1)
      expect(assigns(:subscription).errors[:base]).to eq ["Person muss ausgewählt werden"]
    end

    it "duplicated subscription replaces error" do
      Fabricate(:subscription, mailing_list: list, subscriber: user)

      expect {
        post :create,
          params: {
            group_id: group.id,
            mailing_list_id: list.id,
            subscription: {subscriber_id: user.id},
          }
      }.not_to change(Subscription, :count)

      is_expected.to render_template("crud/new")
      expect(assigns(:subscription).errors.size).to eq(1)
      expect(assigns(:subscription).errors[:base]).to eq ["Person wurde bereits hinzugefügt"]
    end

    it "updates exclude flag for existing subscription" do
      subscription = Fabricate(:subscription, mailing_list: list, subscriber: user, excluded: true)

      expect {
        post :create,
          params: {
            group_id: group.id,
            mailing_list_id: list.id,
            subscription: {subscriber_id: user.id},
          }
      }.not_to change(Subscription, :count)

      expect(subscription.reload).not_to be_excluded
    end

    context "with required person add requests" do
      let(:group) { groups(:bottom_layer_one) }
      let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: group).person }
      let(:person) { Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_two_one)).person }

      it "creates subscription if person already visible" do
        group.update_column(:require_person_add_requests, true)
        post :create,
          params: {
            group_id: group.id,
            mailing_list_id: list.id,
            subscription: {subscriber_id: people(:bottom_member).id},
          }

        expect(list.reload.subscriptions.first.subscriber).to eq(people(:bottom_member))
        expect(people(:bottom_member).add_requests.count).to eq(0)
      end

      it "creates person add request" do
        groups(:bottom_layer_two).update_column(:require_person_add_requests, true)
        post :create,
          params: {
            group_id: group.id,
            mailing_list_id: list.id,
            subscription: {subscriber_id: person.id},
          }

        expect(flash[:alert]).to match(/versendet/)
        expect(list.reload.subscriptions.count).to eq(0)
        expect(person.reload.add_requests.count).to eq(1)
      end

      it "shows notification if person add request already exists" do
        groups(:bottom_layer_two).update_column(:require_person_add_requests, true)
        Person::AddRequest::MailingList.create!(
          person: person,
          requester: user,
          body: list
        )
        post :create,
          params: {
            group_id: group.id,
            mailing_list_id: list.id,
            subscription: {subscriber_id: person.id},
          }

        expect(flash[:alert]).to match(/bereits angefragt/)
        expect(list.reload.subscriptions.count).to eq(0)
        expect(person.reload.add_requests.count).to eq(1)
      end
    end
  end
end
