#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::SubscriptionsController do
  let(:group)         { groups(:bottom_layer_one) }
  let(:top_group)     { groups(:top_group) }
  let(:top_leader)    { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:leaders)       { mailing_lists(:leaders) }
  let(:members)       { mailing_lists(:members) }
  let(:top_group_list){ mailing_lists(:top_group) }


  context 'GET#index' do
    it 'may not index person subscriptions if we do not have no show_detail permission' do
      sign_in(bottom_member)
      expect do
        get :index, params: { group_id: top_group.id, person_id: top_leader.id }
      end.to raise_error CanCan::AccessDenied
    end

    it 'may index my own subscriptions' do
      leaders.subscriptions.create(subscriber: top_leader)
      sign_in(top_leader)
      get :index, params: { group_id: top_group.id, person_id: top_leader.id }
      expect(assigns(:subscribed)).to have(1).items
    end

    it 'sorts subscribed lists by name' do
      first = top_group.mailing_lists.create!(name: '00 - First')
      leaders.subscriptions.create(subscriber: top_leader)
      first.subscriptions.create(subscriber: top_leader)
      sign_in(top_leader)
      get :index, params: { group_id: top_group.id, person_id: top_leader.id }
      expect(assigns(:subscribed)).to eq [first, leaders]
    end

    it 'sorts subscribable lists by name' do
      first = top_group.mailing_lists.create!(name: '00 - First', subscribable: true)
      sign_in(top_leader)
      get :index, params: { group_id: top_group.id, person_id: top_leader.id }
      expect(assigns(:subscribable).to_a).to eq [first, leaders, members, top_group_list]
    end
  end

  context 'POST#create' do
    it 'may not create subscriptions for other user' do
      sign_in(bottom_member)
      expect do
        post :create, params: { group_id: top_group.id, person_id: top_leader.id, id: leaders.id }
      end.to raise_error CanCan::AccessDenied
    end

    it 'may create my own subscriptions' do
      sign_in(top_leader)
      expect do
        post :create, params: { group_id: top_group.id, person_id: top_leader.id, id: leaders.id }
      end.to change { top_leader.subscriptions.count }.by(1)
      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq '<i>Top Leader</i> wurde für <i>Leaders</i> angemeldet.'
    end
  end


  context 'DELETE#destroy' do
    it 'may not delete subscriptions for other user' do
      subscription = leaders.subscriptions.create(subscriber: top_leader)
      list_id = subscription.mailing_list.id

      sign_in(bottom_member)
      expect do
        delete :destroy, params: { group_id: top_group.id, person_id: top_leader.id, id: list_id }
      end.to raise_error CanCan::AccessDenied
    end

    it 'may delete my own subscriptions' do
      subscription = leaders.subscriptions.create(subscriber: top_leader)
      list_id = subscription.mailing_list.id

      sign_in(top_leader)
      expect do
        delete :destroy, params: { group_id: top_group.id, person_id: top_leader.id, id: list_id }
      end.to change { top_leader.subscriptions.count }.by(-1)
      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq '<i>Top Leader</i> wurde von <i>Leaders</i> abgemeldet.'
    end

    it 'may create excluding subscription subscriptions' do
      subscription = leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Leader]
      )
      list_id = subscription.mailing_list.id

      sign_in(top_leader)
      expect do
        delete :destroy, params: { group_id: top_group.id, person_id: top_leader.id, id: list_id }
      end.to change { top_leader.subscriptions.count }.by(1)

      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq '<i>Top Leader</i> wurde von <i>Leaders</i> abgemeldet.'
      expect(top_leader.subscriptions.last.mailing_list).to eq leaders
      expect(top_leader.subscriptions.last).to be_excluded
    end
  end
end
