# encoding: utf-8
# == Schema Information
#
# Table name: subscriptions
#
#  id              :integer          not null, primary key
#  mailing_list_id :integer          not null
#  subscriber_id   :integer          not null
#  subscriber_type :string           not null
#  excluded        :boolean          default(FALSE), not null
#


#  Copyright (c) 2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Subscription do

  context "#possible_groups" do
    it "is valid if descendant group is used" do
      list = Fabricate(:mailing_list, group: groups(:bottom_layer_one))
      subscription = Subscription.new(mailing_list: list, subscriber: groups(:bottom_group_one_one))
      subscription.role_types = [Group::BottomGroup::Leader, Group::BottomGroup::Member]
      expect(subscription).to be_valid
    end

    it "is invalid if other group is used" do
      list = Fabricate(:mailing_list, group: groups(:bottom_layer_one))
      subscription = Subscription.new(mailing_list: list, subscriber: groups(:bottom_layer_two))
      subscription.role_types = [Group::BottomGroup::Leader, Group::BottomGroup::Member]
      expect(subscription).not_to be_valid
    end

    it "does not include deleted groups" do
      list = Fabricate(:mailing_list, group: groups(:bottom_layer_one))
      subscription = Subscription.new(mailing_list: list, subscriber: groups(:bottom_group_one_one))
      subscription.role_types = [Group::BottomGroup::Leader, Group::BottomGroup::Member]

      expect {
        groups(:bottom_group_one_one_one).destroy
      }.to change { subscription.possible_groups.count }.by -1
    end
  end

  context "#possible_events" do
    it "is valid if descendant event is used" do
      event = Fabricate(:event,
                        groups: [groups(:bottom_group_one_one)],
                        dates: [Fabricate(:event_date, start_at: Time.zone.today)])
      list = Fabricate(:mailing_list, group: groups(:bottom_layer_one))
      subscription = Subscription.new(mailing_list: list, subscriber: event)
      expect(subscription).to be_valid
    end

    it "is invalid if other group is used" do
      event = Fabricate(:event,
                        groups: [groups(:top_group)],
                        dates: [Fabricate(:event_date, start_at: Time.zone.today)])
      list = Fabricate(:mailing_list, group: groups(:bottom_layer_one))
      subscription = Subscription.new(mailing_list: list, subscriber: event)
      expect(subscription).not_to be_valid
    end

    it "is invalid if no event is given" do
      list = Fabricate(:mailing_list, group: groups(:bottom_layer_one))
      subscription = Subscription.new(mailing_list: list)
      expect(subscription).not_to be_valid
    end
  end

  context "#to_s" do
    it "renders related group roles" do
      list = Fabricate(:mailing_list, group: groups(:bottom_layer_one))
      subscription = Subscription.new(mailing_list: list, subscriber: groups(:bottom_group_one_one))
      subscription.role_types = [Group::BottomGroup::Leader, Group::BottomGroup::Member]
      expect(subscription.to_s).to eq("Bottom One / Group 11")
    end

    it "renders event label" do
      event = Fabricate(:event,
                        groups: [groups(:bottom_group_one_one)],
                        dates: [Fabricate(:event_date, start_at: Time.zone.today)])
      list = Fabricate(:mailing_list, group: groups(:bottom_layer_one))
      subscription = Subscription.new(mailing_list: list, subscriber: event)
      expect(subscription.to_s).to eq(event.to_s)
    end
  end

  context "#grouped_role_types" do
    it "returns hash with the form {layer: {group: [roles]}}" do
      list = Fabricate(:mailing_list, group: groups(:top_layer))
      subscription = Subscription.new(mailing_list: list, subscriber: groups(:bottom_layer_one))
      subscription.role_types = [Group::BottomLayer::Leader, Group::BottomGroup::Leader,
                                 Group::BottomGroup::Member]
      expect(subscription.grouped_role_types).to eq({
        "Bottom Layer" => {
          "Bottom Layer" => [Group::BottomLayer::Leader],
          "Bottom Group" => [Group::BottomGroup::Leader, Group::BottomGroup::Member]
        }
      })
    end
  end

end
