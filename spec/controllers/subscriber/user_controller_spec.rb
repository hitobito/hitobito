# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe Subscriber::UserController do
  before { sign_in(person) }

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:list) { Fabricate(:mailing_list, group: group, subscribable: true) }

  context "POST create" do
    context "as any user" do
      let(:person) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person }

      it "can create new subscription" do
        expect { post :create, params: {group_id: group.id, mailing_list_id: list.id} }.to change(Subscription, :count).by(1)
      end

      it "cannot create new subscription if mailing list not subscribable" do
        list.update_column(:subscribable, false)
        expect { post :create, params: {group_id: group.id, mailing_list_id: list.id} }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin user" do
      it "creates new subscription" do
        expect { post :create, params: {group_id: group.id, mailing_list_id: list.id} }.to change(Subscription, :count).by(1)
      end

      it "creates new subscription only once" do
        Fabricate(:subscription, mailing_list: list, subscriber: person)

        expect { post :create, params: {group_id: group.id, mailing_list_id: list.id} }.not_to change(Subscription, :count)
      end

      it "updates excluded subscription" do
        subscription = Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: true)
        expect(subscription).to be_excluded
        expect { post :create, params: {group_id: group.id, mailing_list_id: list.id} }.not_to change(Subscription, :count)

        expect(subscription.reload).not_to be_excluded
      end

      after do
        expect(flash[:notice]).to eq "Du wurdest dem Abo erfolgreich hinzugefügt."
        is_expected.to redirect_to group_mailing_list_path(group_id: list.group.id, id: list.id)
      end
    end
  end

  context "POST destroy" do
    it "creates exclusion when no direct subscription exists" do
      Fabricate(:subscription, mailing_list: list, subscriber: groups(:top_group), excluded: false, role_types: [Group::TopGroup::Leader.sti_name])
      expect { post :destroy, params: {group_id: group.id, mailing_list_id: list.id} }.to change { Subscription.count }.by(1)

      expect(person.subscriptions.last).to be_excluded
    end

    it "handle multiple direct and indirect subscription" do
      Fabricate(:subscription, mailing_list: list, subscriber: groups(:top_group), excluded: false, role_types: [Group::TopGroup::Leader.sti_name])
      Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: false)
      expect { post :destroy, params: {group_id: group.id, mailing_list_id: list.id} }.not_to change { Subscription.count }

      expect(person.subscriptions.last).to be_excluded
    end

    it "destroys direct subscription" do
      Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: false)
      expect { post :destroy, params: {group_id: group.id, mailing_list_id: list.id} }.to change { Subscription.count }.by(-1)

      expect(person.subscriptions).to be_empty
    end

    it "does not create exclusion twice" do
      Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: true)

      expect { post :destroy, params: {group_id: group.id, mailing_list_id: list.id} }.not_to change { Subscription.count }
      expect(person.subscriptions.last).to be_excluded
    end

    after do
      expect(flash[:notice]).to eq "Du wurdest erfolgreich vom Abo entfernt."
      is_expected.to redirect_to group_mailing_list_path(group_id: list.group.id, id: list.id)
    end
  end
end
