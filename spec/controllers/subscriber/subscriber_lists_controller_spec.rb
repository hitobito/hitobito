# frozen_string_literal: true

#  Copyright (c) 2023, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Subscriber::SubscriberListsController do
  before { sign_in(person) }

  let(:list) { Fabricate(:mailing_list, group: group, subscribable_for: :anyone) }
  let(:group) { groups(:top_group) }

  context 'POST create' do

    context 'unauthorized' do
      let(:person) { people(:bottom_member) }

      it 'is unauthorized for mailing list without create subscription permission' do
        people = (0...10).map do
          Fabricate(:person)
        end

        expect do
          post :create,
               params: { group_id: group.id, mailing_list_id: list.id,
                         ids: people.map(&:id).join(',') }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'authorized' do
      let(:person) { people(:top_leader) }

      it 'creates multiple person subscriptions for given ids' do
        people = (0...10).map do
          Fabricate(:person)
        end

        expect do
          post :create,
               params: { group_id: group.id, mailing_list_id: list.id,
                         ids: people.map(&:id).join(',') }
        end.to change { Subscription.count }.by(10)

        people.each do |person|
          expect(list.subscribed?(person)).to eq(true)
        end
      end

      it 'ignores person with existing subscription' do
        people = (0...10).map do
          Fabricate(:person)
        end

        subscription_1 = Subscription.create(subscriber: people.first, mailing_list: list)
        subscription_2 = Subscription.create(subscriber: people.second, mailing_list: list)

        expect do
          post :create,
               params: { group_id: group.id, mailing_list_id: list.id,
                         ids: people.map(&:id).join(',') }
        end.to change { Subscription.count }.by(8)

        expect(Subscription.where(subscriber: subscription_1.subscriber,
                                  mailing_list: subscription_1.mailing_list).count).to eq(1)
        expect(Subscription.where(subscriber: subscription_2.subscriber,
                                  mailing_list: subscription_2.mailing_list).count).to eq(1)

        people.each do |person|
          expect(list.subscribed?(person)).to eq(true)
        end
      end
    end
  end
end
