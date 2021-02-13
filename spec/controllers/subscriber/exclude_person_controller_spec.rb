# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Subscriber::ExcludePersonController do
  before { sign_in(person) }

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:list) { Fabricate(:mailing_list, group: group) }

  context "POST create" do
    context "with existing subscription" do
      it "destroys subscription" do
        Fabricate(:subscription, mailing_list: list, subscriber: person)

        expect do
          post :create, params: {group_id: group.id, mailing_list_id: list.id, subscription: {subscriber_id: person.id}}
        end.to change(Subscription, :count).by(-1)
        expect(flash[:notice]).to eq "#{person} wurde erfolgreich ausgeschlossen"
      end

      it "creates exclusion" do
        event = Fabricate(:event_participation, person: person, active: true).event
        event.dates << Fabricate(:event_date, event: event, start_at: Time.zone.today)
        event.groups << group
        Fabricate(:subscription, mailing_list: list, subscriber: event)

        expect do
          post :create, params: {group_id: group.id, mailing_list_id: list.id, subscription: {subscriber_id: person.id}}
        end.to change(Subscription, :count).by(1)
        expect(flash[:notice]).to eq "#{person} wurde erfolgreich ausgeschlossen"
      end

      it "creates exclusion even if person add request is required" do
        group = groups(:bottom_layer_one)
        list = Fabricate(:mailing_list, group: group)
        user = Fabricate(Group::BottomLayer::Leader.name, group: group).person
        sign_in(user)

        person = Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_two_one)).person
        groups(:bottom_layer_two).update_column(:require_person_add_requests, true)

        event = Fabricate(:event_participation, person: person, active: true).event
        event.dates << Fabricate(:event_date, event: event, start_at: Time.zone.today)
        event.groups << group
        Fabricate(:subscription, mailing_list: list, subscriber: event)

        expect do
          post :create, params: {group_id: group.id, mailing_list_id: list.id, subscription: {subscriber_id: person.id}}
        end.to change(Subscription, :count).by(1)
        expect(flash[:notice]).to eq "#{person} wurde erfolgreich ausgeschlossen"
      end

      after do
        expect(list.subscribed?(person)).to be_falsey
      end
    end

    it "without subscriber_id replaces error" do
      post :create, params: {group_id: group.id, mailing_list_id: list.id}

      is_expected.to render_template("crud/new")
      expect(assigns(:subscription).errors.size).to eq(1)
      expect(assigns(:subscription).errors[:base]).to eq ["Person muss ausgewählt werden"]
    end

    it "without valid subscriber_id replaces error" do
      other = Fabricate(:person)
      post :create, params: {group_id: group.id, mailing_list_id: list.id, subscription: {subscriber_id: other.id}}

      is_expected.to render_template("crud/new")
      expect(assigns(:subscription).errors.size).to eq(1)
      expect(assigns(:subscription).errors[:base]).to eq ["#{other} ist nicht Abonnent/-in"]
    end

    it "duplicated subscription replaces error" do
      subscription = list.subscriptions.build
      subscription.update_attribute(:subscriber, person)
      subscription.update_attribute(:excluded, true)

      expect do
        post :create,
          params: {
            group_id: group.id,
            mailing_list_id: list.id,
            subscription: {subscriber_id: person.id}
          }
      end.not_to change(Subscription, :count)

      is_expected.to render_template("crud/new")
      expect(assigns(:subscription).errors.size).to eq(1)
      expect(assigns(:subscription).errors[:base]).to eq ["#{person} ist nicht Abonnent/-in"]
    end
  end
end
