# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JsonApi::MailingListAbility do
  include Subscriptions::SpecHelper

  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:bottom_layer) { groups(:bottom_layer_one) }
  let(:top_group) { groups(:top_group) }
  let(:top_layer) { groups(:top_layer) }
  let(:bottom_member) { people(:bottom_member) }

  before do
    MailingList.all.update_all(subscribable_for: "nobody")
    top_group.mailing_lists.destroy_all
  end

  context "person" do
    def accessible_by(person, model_class = MailingList)
      p = person.is_a?(Symbol) ? people(person) : person
      ability = described_class.new(Ability.new(p))
      model_class.all.accessible_by(ability)
    end

    it "filters mailing lists according to layer" do
      expect(accessible_by(:top_leader)).to have(2).items
      expect(accessible_by(:bottom_member)).to be_empty
    end

    context "bottom group mailing list" do
      let!(:mailing_list) do
        Fabricate(:mailing_list, name: "Test mailing list", group: bottom_group,
          subscribable_for: "nobody")
      end

      it "group_read does not grant reading permission" do
        person = Fabricate(Group::BottomGroup::Member.name.to_sym, group: bottom_group).person
        expect(accessible_by(person)).to be_empty
      end

      it "group_full grants reading permission" do
        person = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: bottom_group).person
        expect(accessible_by(person)).to have(1).items
      end

      it "layer_and_below_read on same layer does not grant reading permission" do
        person = Fabricate(Group::BottomLayer::Member.name.to_sym, group: bottom_layer).person
        expect(accessible_by(person)).to be_empty
      end

      it "layer_full on same layer grants reading permission" do
        person = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: bottom_layer).person
        expect(accessible_by(person)).to have(1).items
      end

      it "layer_and_below_read in layer above does not grant reading permission" do
        person = Fabricate(Group::TopGroup::Secretary.name.to_sym, group: top_group).person
        expect(accessible_by(person)).to be_empty
      end

      it "layer_and_below_full in layer above does not grant reading permission" do
        person = Fabricate(Group::TopGroup::Leader.name.to_sym, group: top_group).person
        expect(accessible_by(person)).to have(2).items
        expect(accessible_by(person)).not_to include(mailing_list)
      end

      it "subscribable_for 'anyone' grants reading permission" do
        person = Fabricate(Group::BottomGroup::Member.name.to_sym, group: bottom_group).person
        mailing_list.update!(subscribable_for: "anyone")
        expect(accessible_by(person)).to have(1).items
      end

      it "subscribable_for 'configured' grants reading permission to configured subscriber" do
        person = Fabricate(Group::BottomGroup::Member.name.to_sym, group: bottom_group).person
        mailing_list.update!(subscribable_for: "configured")
        expect(accessible_by(person)).to be_empty

        create_group_subscription(subscriber: bottom_group, mailing_list: mailing_list,
          excluded: false, role_types: %w[Group::BottomGroup::Member])
        expect(accessible_by(person)).to have(1).items
      end
    end
  end

  context "service token" do
    def accessible_by(token, model_class = MailingList)
      t = token.is_a?(Symbol) ? service_tokens(token) : token
      ability = described_class.new(TokenAbility.new(t))
      model_class.all.accessible_by(ability)
    end

    it "filters mailing lists according to layer" do
      expect(accessible_by(:permitted_top_layer_token)).to have(2).items
      expect(accessible_by(:permitted_bottom_layer_token)).to be_empty
    end

    context "bottom group mailing list" do
      let!(:mailing_list) do
        Fabricate(:mailing_list, name: "Test mailing list", group: bottom_group,
          subscribable_for: "nobody")
      end

      it "layer_read does not grant reading permission" do
        token = Fabricate(:service_token, layer: bottom_layer, mailing_lists: true,
          permission: :layer_read)
        expect(accessible_by(token)).to be_empty
      end

      it "layer_and_below_read on same layer does not grant reading permission" do
        token = Fabricate(:service_token, layer: bottom_layer, mailing_lists: true,
          permission: :layer_and_below_read)
        expect(accessible_by(token)).to be_empty
      end

      it "layer_full on same layer grants reading permission" do
        token = Fabricate(:service_token, layer: bottom_layer, mailing_lists: true,
          permission: :layer_full)
        expect(accessible_by(token)).to have(1).items
      end

      it "layer_and_below_read in layer above does not grant reading permission" do
        token = Fabricate(:service_token, layer: top_layer, mailing_lists: true,
          permission: :layer_and_below_read)
        expect(accessible_by(token)).to be_empty
      end

      it "layer_and_below_full in layer above does not grant reading permission" do
        token = Fabricate(:service_token, layer: top_layer, mailing_lists: true,
          permission: :layer_and_below_full)
        expect(accessible_by(token)).to have(2).items
        expect(accessible_by(token)).not_to include(mailing_list)
      end

      it "subscribable_for 'anyone' grants reading permission" do
        token = Fabricate(:service_token, layer: bottom_layer, mailing_lists: true,
          permission: :layer_read)
        mailing_list.update!(subscribable_for: "anyone")
        expect(accessible_by(token)).to have(1).items
      end

      it "subscribable_for 'configured' is still not readable by service token" do
        token = Fabricate(:service_token, layer: bottom_layer, mailing_lists: true,
          permission: :layer_read)
        mailing_list.update!(subscribable_for: "configured")
        expect(accessible_by(token)).to be_empty

        create_group_subscription(subscriber: bottom_group, mailing_list: mailing_list,
          excluded: false, role_types: %w[Group::BottomGroup::Member])
        expect(accessible_by(token)).to be_empty
      end
    end
  end
end
