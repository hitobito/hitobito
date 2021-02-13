# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailingListAbility do
  let(:user) { role.person }
  let(:group) { role.group }
  let(:list) { Fabricate(:mailing_list, group: group) }

  subject { Ability.new(user.reload) }

  context "layer and below full" do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    context "in own group" do
      it "may show mailing lists" do
        is_expected.to be_able_to(:show, list)
      end

      it "may update mailing lists" do
        is_expected.to be_able_to(:update, list)
      end

      it "may index subscriptions" do
        is_expected.to be_able_to(:index_subscriptions, list)
      end

      it "may create subscriptions" do
        is_expected.to be_able_to(:create, list.subscriptions.new)
      end

      it "may export empty subscriptions" do
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with role types from lower groups" do
        create_group_subscription(Group::TopGroup::Leader, Group::GlobalGroup::Member)
        is_expected.to be_able_to(:export_subscriptions, list)
      end
    end

    context "in group in same layer" do
      let(:group) { groups(:top_layer) }

      it "may show mailing lists" do
        is_expected.to be_able_to(:show, list)
      end

      it "may update mailing lists" do
        is_expected.to be_able_to(:update, list)
      end

      it "may index subscriptions" do
        is_expected.to be_able_to(:index_subscriptions, list)
      end

      it "may create subscriptions" do
        is_expected.to be_able_to(:create, list.subscriptions.new)
      end

      it "may export empty subscriptions" do
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with role types from lower layers" do
        create_group_subscription(Group::TopGroup::Leader, Group::BottomGroup::Member, Group::GlobalGroup::Leader)
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with events from lower layers" do
        create_event_subscription(groups(:bottom_layer_one))
        is_expected.to be_able_to(:export_subscriptions, list)
      end
    end

    context "in global group in same layer" do
      let(:group) { groups(:toppers) }

      it "may export subscriptions with role types from local layers" do
        create_group_subscription(Group::GlobalGroup::Member)
        is_expected.to be_able_to(:export_subscriptions, list)
      end
    end

    context "in group in lower layer" do
      let(:group) { groups(:bottom_layer_one) }

      it "may not show mailing lists" do
        is_expected.not_to be_able_to(:show, list)
      end

      it "may not update mailing lists" do
        is_expected.not_to be_able_to(:update, list)
      end

      it "may not index subscriptions" do
        is_expected.not_to be_able_to(:index_subscriptions, list)
      end

      it "may not export subscriptions" do
        is_expected.not_to be_able_to(:export_subscriptions, list)
      end

      it "may not create subscriptions" do
        is_expected.not_to be_able_to(:create, list.subscriptions.new)
      end
    end

    context "in group in upper layer" do
      let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }
      let(:group) { groups(:top_layer) }

      it "may not show mailing lists" do
        is_expected.not_to be_able_to(:show, list)
      end

      it "may not update mailing lists" do
        is_expected.not_to be_able_to(:update, list)
      end

      it "may not index subscriptions" do
        is_expected.not_to be_able_to(:index_subscriptions, list)
      end

      it "may not export subscriptions" do
        is_expected.not_to be_able_to(:export_subscriptions, list)
      end

      it "may not create subscriptions" do
        is_expected.not_to be_able_to(:create, list.subscriptions.new)
      end
    end
  end

  context "layer full" do
    let(:role) { Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_one)) }

    context "in own group" do
      it "may show mailing lists" do
        is_expected.to be_able_to(:show, list)
      end

      it "may update mailing lists" do
        is_expected.to be_able_to(:update, list)
      end

      it "may index subscriptions" do
        is_expected.to be_able_to(:index_subscriptions, list)
      end

      it "may create subscriptions" do
        is_expected.to be_able_to(:create, list.subscriptions.new)
      end

      it "may export empty subscriptions" do
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with role types from local groups" do
        create_group_subscription(Group::BottomLayer::Member, Group::BottomGroup::Member)
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with role types from global groups if bottom layer" do
        create_group_subscription(Group::GlobalGroup::Leader)
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with events from lower groups" do
        create_event_subscription(groups(:bottom_group_one_one))
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with events shared with neighbouring group" do
        create_event_subscription(*groups(:bottom_layer_one, :bottom_layer_two))
        is_expected.to be_able_to(:export_subscriptions, list)
      end
    end

    context "in top group" do
      let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

      it "may export subscriptions with role types from local groups" do
        create_group_subscription(Group::TopGroup::Member, Group::TopLayer::TopAdmin)
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may not export subscriptions with role types from below groups" do
        create_group_subscription(Group::BottomLayer::Member, Group::BottomGroup::Member)
        is_expected.not_to be_able_to(:export_subscriptions, list)
      end

      it "may not export subscriptions with role types from global groups" do
        create_group_subscription(Group::GlobalGroup::Leader)
        is_expected.not_to be_able_to(:export_subscriptions, list)
      end

      context "in top layer" do
        let(:group) { groups(:top_layer) }

        it "may not export subscriptions with events from lower layers" do
          create_event_subscription(groups(:bottom_layer_one))
          is_expected.not_to be_able_to(:export_subscriptions, list)
        end
      end
    end

    context "in global group in same layer" do
      let(:group) { Fabricate(Group::GlobalGroup.name, parent: groups(:bottom_layer_one)) }

      it "may export subscriptions with role types from local layers" do
        create_group_subscription(Group::GlobalGroup::Member)
        is_expected.to be_able_to(:export_subscriptions, list)
      end
    end
  end

  context "group and below full" do
    let(:role) { Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: groups(:top_layer)) }

    context "in own group" do
      it "may show mailing lists" do
        is_expected.to be_able_to(:show, list)
      end

      it "may update mailing lists" do
        is_expected.to be_able_to(:update, list)
      end

      it "may index subscriptions" do
        is_expected.to be_able_to(:index_subscriptions, list)
      end

      it "may create subscriptions" do
        is_expected.to be_able_to(:create, list.subscriptions.new)
      end

      it "may export empty subscriptions" do
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with role types from local groups" do
        create_group_subscription(Group::TopGroup::Member)
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with role types from global groups" do
        create_group_subscription(Group::TopGroup::Member, Group::GlobalGroup::Leader)
        is_expected.not_to be_able_to(:export_subscriptions, list)
      end

      it "may not export subscriptions with role types from lower layers" do
        create_group_subscription(Group::TopGroup::Leader, Group::BottomGroup::Leader)
        is_expected.not_to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with events from lower groups" do
        create_event_subscription(groups(:top_group))
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may not export subscriptions with events from lower layer" do
        create_event_subscription(groups(:bottom_group_one_one))
        is_expected.not_to be_able_to(:export_subscriptions, list)
      end
    end

    context "in group in same layer" do
      let(:group) { groups(:top_group) }

      it "may show mailing lists" do
        is_expected.to be_able_to(:show, list)
      end

      it "may update mailing lists" do
        is_expected.to be_able_to(:update, list)
      end

      it "may index subscriptions" do
        is_expected.to be_able_to(:index_subscriptions, list)
      end

      it "may create subscriptions" do
        is_expected.to be_able_to(:create, list.subscriptions.new)
      end

      it "may export empty subscriptions" do
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with role types from local layers" do
        create_group_subscription(Group::TopGroup::Member)
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with events" do
        create_event_subscription(groups(:top_group))
        is_expected.to be_able_to(:export_subscriptions, list)
      end
    end

    context "in global group below" do
      let(:group) { groups(:toppers) }

      it "may export subscriptions with role types from local layers" do
        create_group_subscription(Group::GlobalGroup::Member)
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with events" do
        create_event_subscription(groups(:toppers))
        is_expected.to be_able_to(:export_subscriptions, list)
      end
    end

    context "in group in lower layer" do
      let(:group) { groups(:bottom_layer_one) }

      it "may not show mailing lists" do
        is_expected.not_to be_able_to(:show, list)
      end

      it "may not update mailing lists" do
        is_expected.not_to be_able_to(:update, list)
      end

      it "may not index subscriptions" do
        is_expected.not_to be_able_to(:index_subscriptions, list)
      end

      it "may not export subscriptions" do
        is_expected.not_to be_able_to(:export_subscriptions, list)
      end

      it "may not create subscriptions" do
        is_expected.not_to be_able_to(:create, list.subscriptions.new)
      end
    end

    context "for destroyed group" do
      let(:group) { groups(:toppers) }

      before { list; group.destroy }

      it "may not create mailing list" do
        is_expected.not_to be_able_to(:create, list)
      end

      it "may not update mailing list" do
        is_expected.not_to be_able_to(:update, list)
      end

      it "may not create subscription" do
        is_expected.not_to be_able_to(:create, list.subscriptions.new)
      end
    end
  end

  context "group full" do
    let(:role) { Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers)) }

    context "in own group" do
      it "may show mailing lists" do
        is_expected.to be_able_to(:show, list)
      end

      it "may update mailing lists" do
        is_expected.to be_able_to(:update, list)
      end

      it "may index subscriptions" do
        is_expected.to be_able_to(:index_subscriptions, list)
      end

      it "may export empty subscriptions" do
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with local role types" do
        create_group_subscription(Group::GlobalGroup::Member)
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may not export subscriptions with lower role types" do
        group = groups(:top_group)
        role = Fabricate(Group::TopGroup::Secretary.name.to_sym, group: group)
        list = Fabricate(:mailing_list, group: group)
        ability = Ability.new(role.person.reload)
        Subscription.create!(mailing_list: list, subscriber: group, role_types: [Group::TopGroup::Member, Group::GlobalGroup::Member])

        expect(ability).not_to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with events" do
        create_event_subscription(groups(:toppers))
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may export subscriptions with events shared with siblings" do
        other = Fabricate(Group::GlobalGroup.name, parent: groups(:top_layer))
        create_event_subscription(group, other)
        is_expected.to be_able_to(:export_subscriptions, list)
      end

      it "may not export subscriptions with events in lower groups" do
        group = groups(:top_group)
        role = Fabricate(Group::TopGroup::Secretary.name.to_sym, group: group)
        list = Fabricate(:mailing_list, group: group)
        ability = Ability.new(role.person.reload)
        child = Fabricate(Group::GlobalGroup.name, parent: group)
        event = Fabricate(:event, groups: [child], dates: [Fabricate(:event_date, start_at: Time.zone.today)])
        group.reload
        Subscription.create!(mailing_list: list, subscriber: event)

        expect(ability).not_to be_able_to(:export_subscriptions, list)
      end

      it "may create subscriptions" do
        is_expected.to be_able_to(:create, list.subscriptions.new)
      end
    end

    context "in group in same layer" do
      let(:group) { groups(:top_group) }

      it "may not show mailing lists" do
        is_expected.not_to be_able_to(:show, list)
      end

      it "may not update mailing lists" do
        is_expected.not_to be_able_to(:update, list)
      end

      it "may not index subscriptions" do
        is_expected.not_to be_able_to(:index_subscriptions, list)
      end

      it "may not create subscriptions" do
        is_expected.not_to be_able_to(:create, list.subscriptions.new)
      end
    end

    context "in group in lower layer" do
      let(:group) { groups(:bottom_layer_one) }

      it "may not show mailing lists" do
        is_expected.not_to be_able_to(:show, list)
      end

      it "may not update mailing lists" do
        is_expected.not_to be_able_to(:update, list)
      end

      it "may not index subscriptions" do
        is_expected.not_to be_able_to(:index_subscriptions, list)
      end

      it "may not create subscriptions" do
        is_expected.not_to be_able_to(:create, list.subscriptions.new)
      end
    end
  end

  def create_group_subscription(*role_types)
    Subscription.create!(mailing_list: list, subscriber: group, role_types: role_types)
  end

  def create_event_subscription(*groups)
    event = Fabricate(:event, groups: groups, dates: [Fabricate(:event_date, start_at: Time.zone.today)])
    Subscription.create!(mailing_list: list, subscriber: event)
  end
end
