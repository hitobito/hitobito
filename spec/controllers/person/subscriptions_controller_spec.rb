#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::SubscriptionsController do
  let(:group) { groups(:bottom_layer_one) }
  let(:top_layer) { groups(:top_layer) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_layer) { groups(:bottom_layer_one) }
  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:leaders) { mailing_lists(:leaders) }
  let(:members) { mailing_lists(:members) }
  let(:top_group_list) { mailing_lists(:top_group) }

  context "GET#index" do
    render_views

    it "may not index person subscriptions if we do not have no show_detail permission" do
      sign_in(bottom_member)
      expect do
        get :index, params: {group_id: top_group.id, person_id: top_leader.id}
      end.to raise_error CanCan::AccessDenied
    end

    it "may index my own subscriptions" do
      leaders.subscriptions.create(subscriber: top_leader)
      sign_in(top_leader)
      get :index, params: {group_id: top_group.id, person_id: top_leader.id}
      expect(assigns(:grouped_subscribed)).to have(1).items
    end

    it "sorts subscribed lists by name and groups by layer" do
      first = bottom_group.mailing_lists.create!(name: "00 - First")
      leaders.subscriptions.create(subscriber: top_leader)
      first.subscriptions.create(subscriber: top_leader)
      sign_in(top_leader)
      get :index, params: {group_id: top_group.id, person_id: top_leader.id}
      expect(assigns(:grouped_subscribed)).to eq({bottom_layer => [first], top_layer => [leaders]})
    end

    it "sorts subscribable lists by name" do
      first = bottom_group.mailing_lists.create!(name: "00 - First", subscribable_for: :anyone)
      sign_in(top_leader)
      get :index, params: {group_id: top_group.id, person_id: top_leader.id}
      expect(assigns(:grouped_subscribable)).to eq({bottom_layer => [first],
top_layer => [leaders, members, top_group_list]})
    end
  end

  context "POST#create" do
    it "may not create subscriptions for other user" do
      sign_in(bottom_member)
      expect do
        post :create, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
      end.to raise_error CanCan::AccessDenied
    end

    it "may create my own subscriptions" do
      sign_in(top_leader)
      expect do
        post :create, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
      end.to change { top_leader.subscriptions.count }.by(1)
      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq "<i>Top Leader</i> wurde für <i>Leaders</i> angemeldet."
    end

    it "may not create subscription for non-subscribable mailing list" do
      leaders.update!(subscribable_for: :nobody)
      sign_in(top_leader)
      expect do
        expect do
          post :create, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
        end.to raise_error(ActiveRecord::RecordNotFound)
      end.not_to change { top_leader.subscriptions.count }
    end

    it "may create subscription for subscribable mailing list if configured" do
      leaders.update!(subscribable_for: :configured, subscribable_mode: :opt_in)
      leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Leader]
      )
      sign_in(top_leader)
      expect do
        post :create, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
      end.to change { top_leader.subscriptions.count }.by(1)
      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq "<i>Top Leader</i> wurde für <i>Leaders</i> angemeldet."
    end

    it "may create subscription for subscribable mailing list if configured and opt-out, but does nothing" do
      leaders.update!(subscribable_for: :configured, subscribable_mode: :opt_out)
      leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Leader]
      )
      sign_in(top_leader)
      expect do
        post :create, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
      end.not_to change { top_leader.subscriptions.count }
      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq "<i>Top Leader</i> wurde für <i>Leaders</i> angemeldet."
    end

    it "may not create subscription for subscribable mailing list if not configured" do
      leaders.update!(subscribable_for: :configured, subscribable_mode: :opt_in)
      leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Member]
      )
      sign_in(top_leader)
      expect do
        expect do
          post :create, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
        end.to raise_error(ActiveRecord::RecordNotFound)
      end.not_to change { top_leader.subscriptions.count }
    end
  end

  context "DELETE#destroy" do
    it "may not delete subscriptions for other user" do
      leaders.subscriptions.create(subscriber: top_leader)

      sign_in(bottom_member)
      expect do
        delete :destroy, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
      end.to raise_error CanCan::AccessDenied
    end

    it "may delete my own subscriptions" do
      leaders.subscriptions.create(subscriber: top_leader)

      sign_in(top_leader)
      expect do
        delete :destroy, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
      end.to change { top_leader.subscriptions.count }.by(-1)
      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq "<i>Top Leader</i> wurde von <i>Leaders</i> abgemeldet."
    end

    it "may not delete subscriptions for direct subscription in non-subscribable mailing list" do
      leaders.update!(subscribable_for: :nobody)
      leaders.subscriptions.create(subscriber: top_leader)

      sign_in(top_leader)
      expect do
        expect do
          delete :destroy, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
        end.to raise_error(ActiveRecord::RecordNotFound)
      end.not_to change { top_leader.subscriptions.count }
    end

    it "may not delete subscriptions for group subscription in non-subscribable mailing list" do
      leaders.update!(subscribable_for: :nobody)
      leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Leader]
      )

      sign_in(top_leader)
      expect do
        expect do
          delete :destroy, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
        end.to raise_error(ActiveRecord::RecordNotFound)
      end.not_to change { top_leader.subscriptions.count }
    end

    it "may delete subscriptions for subscribable mailing list if configured and opt-out" do
      leaders.update!(subscribable_for: :configured, subscribable_mode: :opt_out)
      leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Leader]
      )

      sign_in(top_leader)
      expect do
        delete :destroy, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
      end.to change { top_leader.subscriptions.count }.by(1)
      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq "<i>Top Leader</i> wurde von <i>Leaders</i> abgemeldet."
    end

    it "may delete subscriptions for subscribable mailing list if configured and opt-in" do
      leaders.update!(subscribable_for: :configured, subscribable_mode: :opt_in)
      leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Leader]
      )
      leaders.subscriptions.create(subscriber: top_leader)

      sign_in(top_leader)
      expect do
        delete :destroy, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
      end.to change { top_leader.subscriptions.count }.by(-1)
      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq "<i>Top Leader</i> wurde von <i>Leaders</i> abgemeldet."
    end

    it "does not delete subscriptions for subscribable mailing list if configured and opt-in but not subscribed" do
      leaders.update!(subscribable_for: :configured, subscribable_mode: :opt_in)
      leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Leader]
      )

      sign_in(top_leader)
      expect do
        delete :destroy, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
      end.not_to change { top_leader.subscriptions.count }
      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq "<i>Top Leader</i> wurde von <i>Leaders</i> abgemeldet."
    end

    it "may not delete subscriptions for subscribable mailing list if not configured" do
      leaders.update!(subscribable_for: :configured, subscribable_mode: :opt_out)
      leaders.subscriptions.create(subscriber: top_leader)
      leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Member]
      )

      sign_in(top_leader)
      expect do
        expect do
          delete :destroy, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
        end.to raise_error(ActiveRecord::RecordNotFound)
      end.not_to change { top_leader.subscriptions.count }
    end

    it "may not delete subscriptions for subscribable mailing list if not configured and opt-in" do
      leaders.update!(subscribable_for: :configured, subscribable_mode: :opt_in)
      leaders.subscriptions.create(subscriber: top_leader)
      leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Member]
      )

      sign_in(top_leader)
      expect do
        expect do
          delete :destroy, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
        end.to raise_error(ActiveRecord::RecordNotFound)
      end.not_to change { top_leader.subscriptions.count }
    end

    it "may create group subscription exclusion" do
      leaders.subscriptions.create(
        subscriber: top_group,
        role_types: [Group::TopGroup::Leader]
      )

      sign_in(top_leader)
      expect do
        delete :destroy, params: {group_id: top_group.id, person_id: top_leader.id, id: leaders.id}
      end.to change { top_leader.subscriptions.count }.by(1)

      expect(response).to redirect_to group_person_subscriptions_path(top_group, top_leader)
      expect(flash[:notice]).to eq "<i>Top Leader</i> wurde von <i>Leaders</i> abgemeldet."
      expect(top_leader.subscriptions.last.mailing_list).to eq leaders
      expect(top_leader.subscriptions.last).to be_excluded
    end
  end
end
