# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: groups
#
#  id                                      :integer          not null, primary key
#  address_care_of                         :string
#  archived_at                             :datetime
#  country                                 :string
#  custom_self_registration_title          :string
#  deleted_at                              :datetime
#  description                             :text
#  email                                   :string
#  encrypted_text_message_password         :string
#  encrypted_text_message_username         :string
#  housenumber                             :string(20)
#  letter_address_position                 :string           default("left"), not null
#  lft                                     :integer
#  main_self_registration_group            :boolean          default(FALSE), not null
#  name                                    :string
#  nextcloud_url                           :string
#  postbox                                 :string
#  privacy_policy                          :string
#  privacy_policy_title                    :string
#  require_person_add_requests             :boolean          default(FALSE), not null
#  rgt                                     :integer
#  self_registration_notification_email    :string
#  self_registration_require_adult_consent :boolean          default(FALSE), not null
#  self_registration_role_type             :string
#  short_name                              :string(31)
#  street                                  :string
#  text_message_originator                 :string
#  text_message_provider                   :string           default("aspsms"), not null
#  town                                    :string
#  type                                    :string           not null
#  zip_code                                :integer
#  created_at                              :datetime
#  updated_at                              :datetime
#  contact_id                              :integer
#  creator_id                              :integer
#  deleter_id                              :integer
#  layer_group_id                          :integer
#  parent_id                               :integer
#  updater_id                              :integer
#
# Indexes
#
#  groups_search_column_gin_idx    (search_column) USING gin
#  index_groups_on_layer_group_id  (layer_group_id)
#  index_groups_on_lft_and_rgt     (lft,rgt)
#  index_groups_on_parent_id       (parent_id)
#  index_groups_on_type            (type)
#

require "spec_helper"

describe Group do
  it "should load fixtures" do
    expect(groups(:top_layer)).to be_present
  end

  it "is a valid nested set" do
    expect(Group).to be_valid
  end

  it "fixtures should have correct layer_group_id values" do
    fixture_values = Group.order(:id).pluck(:layer_group_id)

    set_layer_group_id = lambda do |group|
      group.update(id: group.id) # triggers after_update :set_layer_group_id
      group.children.each(&set_layer_group_id)
    end
    Group.where(parent_id: nil).find_each(&set_layer_group_id)

    expect(fixture_values).to eq Group.order(:id).pluck(:layer_group_id)
  end

  context "#roles" do
    let(:group) { groups(:top_group) }

    it "includes open ended roles" do
      role = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
      expect(group.roles).to include(role)
    end

    it "includes active roles with start_on and end_on set" do
      role = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group,
        start_on: 1.day.ago, end_on: 1.day.from_now)
      expect(group.roles).to include(role)
    end

    it "includes future roles" do
      role = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group, start_on: 1.day.from_now)
      expect(group.roles).to include(role)
    end

    it "excludes past roles" do
      role = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group, end_on: 1.day.ago)
      expect(group.roles).not_to include(role)
    end
  end

  context "alphabetic order" do
    context "on insert" do
      it "at the beginning" do
        updated = 2.days.ago.to_date
        Group.update_all(updated_at: updated)
        expect(groups(:top_layer).reload.updated_at.to_date).to eq(updated)
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: "AAA", parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "AAA", "Bottom One", "Bottom Two", "TopGroup", "Toppers"
        ]
        # :updated_at should not change, tests patch from config/awesome_nested_set_patch.rb
        expect(groups(:top_layer).reload.updated_at.to_date).to eq(updated)
        expect(groups(:bottom_layer_one).reload.updated_at.to_date).to eq(updated)
        expect(groups(:bottom_layer_two).reload.updated_at.to_date).to eq(updated)
      end

      it "at the beginning with same name" do
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: "Bottom One", parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "Bottom One", "Bottom Two", "TopGroup", "Toppers"
        ]
      end

      it "in the middle" do
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: "Frosch", parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "Bottom Two", "Frosch", "TopGroup", "Toppers"
        ]
      end

      it "in the middle with same name" do
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: "Bottom Two", parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "Bottom Two", "Bottom Two", "TopGroup", "Toppers"
        ]
      end

      it "at the end" do
        parent = groups(:top_layer)
        group = Group::TopGroup.new(name: "ZZ Top", parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "Bottom Two", "TopGroup", "Toppers", "ZZ Top"
        ]
      end

      it "at the end with same name" do
        parent = groups(:top_layer)
        group = Group::TopGroup.new(name: "Toppers", parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "Bottom Two", "TopGroup", "Toppers", "Toppers"
        ]
      end

      context "with short_name" do
        it "in the middle" do
          parent = groups(:top_layer)
          group = Group::TopGroup.new(name: "Bottom A", short_name: "Bottom X",
            parent_id: parent.id)
          group.save!
          expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
            "Bottom One", "Bottom Two", "Bottom A", "TopGroup", "Toppers"
          ]
        end
      end

      context "with lowercase" do
        it "in the middle" do
          parent = groups(:top_layer)
          group = Group::TopGroup.new(name: "bottom x", parent_id: parent.id)
          group.save!
          expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
            "Bottom One", "Bottom Two", "bottom x", "TopGroup", "Toppers"
          ]
        end
      end
    end

    context "on update" do
      it "at the beginning" do
        groups(:bottom_layer_two).update!(name: "AAA")
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "AAA", "Bottom One", "TopGroup", "Toppers"
        ]
      end

      it "at the beginning with same name" do
        groups(:bottom_layer_two).update!(name: "Bottom One")
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "Bottom One", "TopGroup", "Toppers"
        ]
      end

      it "in the middle keeping position right" do
        groups(:bottom_layer_two).update!(name: "Frosch")
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "Frosch", "TopGroup", "Toppers"
        ]
      end

      it "in the middle keeping position left" do
        groups(:bottom_layer_two).update!(name: "Bottom P")
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "Bottom P", "TopGroup", "Toppers"
        ]
      end

      it "in the middle moving right" do
        groups(:bottom_layer_two).update!(name: "TopGzzz")
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "TopGroup", "TopGzzz", "Toppers"
        ]
      end

      it "in the middle moving left" do
        groups(:top_group).update!(name: "Bottom P")
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "Bottom P", "Bottom Two", "Toppers"
        ]
      end

      it "in the middle with same name" do
        groups(:bottom_layer_two).update!(name: "TopGroup")
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "TopGroup", "TopGroup", "Toppers"
        ]
      end

      it "at the end" do
        groups(:bottom_layer_two).update!(name: "ZZ Top")
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "TopGroup", "Toppers", "ZZ Top"
        ]
      end

      it "at the end with same name" do
        groups(:bottom_layer_two).update!(name: "Toppers")
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          "Bottom One", "TopGroup", "Toppers", "Toppers"
        ]
      end

      context "with short_name" do
        it "at the end" do
          groups(:bottom_layer_two).update!(short_name: "ZZZ")
          expect(groups(:top_layer).children.order(:lft).collect(&:display_name)).to eq [
            "Bottom One",
            "TopGroup",
            "Toppers",
            "ZZZ"
          ]
        end
      end

      context "with lowercase" do
        it "in the middle" do
          groups(:bottom_layer_two).update!(name: "topGroupX")
          expect(groups(:top_layer).children.order(:lft).collect(&:display_name)).to eq [
            "Bottom One", "TopGroup", "topGroupX", "Toppers"
          ]
        end
      end
    end
  end

  context "#hierachy" do
    it "is itself for root group" do
      expect(groups(:top_layer).hierarchy).to eq([groups(:top_layer)])
    end

    it "contains all ancestors" do
      expect(groups(:bottom_group_one_one).hierarchy).to eq(
        [
          groups(:top_layer),
          groups(:bottom_layer_one),
          groups(:bottom_group_one_one)
        ]
      )
    end
  end

  context "#layer_hierarchy" do
    it "is itself for top layer" do
      expect(groups(:top_layer).layer_hierarchy).to eq([groups(:top_layer)])
    end

    it "is next upper layer for top layer group" do
      expect(groups(:top_group).layer_hierarchy).to eq([groups(:top_layer)])
    end

    it "is all upper layers for regular layer" do
      expect(groups(:bottom_layer_one).layer_hierarchy).to eq([groups(:top_layer),
        groups(:bottom_layer_one)])
    end
  end

  context "#layer_group" do
    it "is itself for layer" do
      expect(groups(:top_layer).layer_group).to eq(groups(:top_layer))
    end

    it "is next upper layer for regular group" do
      expect(groups(:bottom_group_one_one).layer_group).to eq(groups(:bottom_layer_one))
    end
  end

  context "#upper_layer_hierarchy" do
    context "for existing group" do
      it "contains only upper for layer" do
        expect(groups(:bottom_layer_one).upper_layer_hierarchy).to eq([groups(:top_layer)])
      end

      it "contains only upper for group" do
        expect(groups(:bottom_group_one_one).upper_layer_hierarchy).to eq([groups(:top_layer)])
      end

      it "is empty for top layer" do
        expect(groups(:top_group).upper_layer_hierarchy).to be_empty
      end
    end

    context "for new group" do
      it "contains only upper for layer" do
        group = Group::BottomLayer.new
        group.parent = groups(:top_layer)
        expect(group.upper_layer_hierarchy).to eq([groups(:top_layer)])
      end

      it "contains only upper for group" do
        group = Group::BottomGroup.new
        group.parent = groups(:bottom_layer_one)
        expect(group.upper_layer_hierarchy).to eq([groups(:top_layer)])
      end

      it "is empty for top layer" do
        group = Group::TopGroup.new
        group.parent = groups(:top_layer)
        expect(group.upper_layer_hierarchy).to be_empty
      end
    end
  end

  context "#sister_groups_with_descendants" do
    subject { group.sister_groups_with_descendants.to_a }

    context "for root" do
      let(:group) { groups(:top_layer) }

      it "contains all groups" do
        is_expected.to match_array(Group.all)
      end
    end

    context "for group without children or sisters" do
      let(:group) { groups(:top_group) }

      it "only contains self" do
        is_expected.to eq([group])
      end
    end

    context "for layer" do
      let(:group) { groups(:bottom_layer_one) }

      it "contains other layers and their descendants" do
        is_expected.to match_array([group.self_and_descendants,
          groups(:bottom_layer_two).self_and_descendants].flatten)
      end
    end

    context "for group" do
      let(:group) { groups(:bottom_group_one_one) }

      it "contains other groups and their descendants" do
        is_expected.to match_array([group, groups(:bottom_group_one_one_one),
          groups(:bottom_group_one_two)])
      end
    end
  end

  context ".all_types" do
    it "lists all types" do
      expect(Group.all_types).to contain_exactly(
        Group::TopLayer, Group::TopGroup, Group::BottomLayer, Group::BottomGroup,
        Group::GlobalGroup, Group::MountedAttrsGroup, Group::StaticNameAGroup,
        Group::StaticNameBGroup
      )
    end
  end

  context ".order_by_type" do
    it "has correct ordering without group" do
      expect(Group.order_by_type).to eq([groups(:top_layer),
        groups(:top_group),
        groups(:bottom_layer_one),
        groups(:bottom_layer_two),
        groups(:bottom_group_one_one),
        groups(:bottom_group_one_one_one),
        groups(:bottom_group_one_two),
        groups(:bottom_group_two_one),
        groups(:toppers)])
    end

    it "has correct ordering with parent group" do
      parent = groups(:top_layer)
      expect(parent.children.order_by_type).to eq(
        [groups(:top_group),
          groups(:bottom_layer_one),
          groups(:bottom_layer_two),
          groups(:toppers)]
      )
    end

    it "works without possible groups" do
      parent = groups(:bottom_group_one_two)
      expect(parent.children.order_by_type).to be_empty
    end
  end

  context "#set_layer_group_id" do
    it "sets layer_group_id on group" do
      top_layer = groups(:top_layer)
      group = Group::TopGroup.new(name: "foobar")
      group.parent_id = top_layer.id
      group.save!
      expect(group.layer_group_id).to eq top_layer.id
    end

    it "sets layer_group_id on group with default children" do
      group = Group::TopLayer.new(name: "foobar")
      group.save!
      expect(group.layer_group_id).to eq group.id
      expect(group.children).to be_present
      expect(group.children.first.layer_group_id).to eq group.id
    end

    it "sets the layer group on all descendants if parent changes" do
      group = groups(:bottom_group_one_one)
      group.update!(parent_id: groups(:bottom_layer_two).id)
      expect(group.reload.layer_group_id).to eq(groups(:bottom_layer_two).id)
      expect(groups(:bottom_group_one_one_one).layer_group_id).to eq(groups(:bottom_layer_two).id)
    end
  end

  context "#destroy" do
    let(:top_leader) { roles(:top_leader) }
    let(:top_layer) { groups(:top_layer) }
    let(:bottom_layer) { groups(:bottom_layer_one) }
    let(:bottom_group) { groups(:bottom_group_one_two) }

    it "destroys self" do
      expect { bottom_group.destroy }.to change { Group.without_deleted.count }.by(-1)
      expect(Group.only_deleted.collect(&:id)).to match_array([bottom_group.id])
      expect(Group).to be_valid
    end

    it "hard destroys self" do
      expect { bottom_group.really_destroy! }.to change { Group.with_deleted.count }.by(-1)
      expect(Group).to be_valid
    end

    it "protects group with children" do
      expect { bottom_layer.destroy }.not_to(change { Group.without_deleted.count })
    end

    it "does not destroy anything for root group" do
      expect { top_layer.destroy }.not_to(change { Group.count })
    end

    describe "archived group" do
      let(:top_group) { groups(:top_group) }
      let(:top_leader) { roles(:top_leader) }

      before { top_group.archive! }

      it "soft destroys group" do
        expect { top_group.destroy }.to change { Group.deleted.count }.by(1)
      end

      it "soft destroys role if role is old enough to archive" do
        top_leader.update_columns(created_at: 1.year.ago, start_on: 1.year.ago)
        expect { top_group.destroy }.to change { Role.ended.count }.by(1)
      end
    end

    context "role assignments" do
      it "terminates own roles" do
        _role = Fabricate(Group::BottomGroup::Member.name.to_s, group: bottom_group)
        _deleted_ids = bottom_group.roles.collect(&:id)
        # role is deleted permanantly as it is less than Settings.role.minimum_days_to_archive old
        expect { bottom_group.destroy }.to change { Role.with_inactive.count }.by(-1)
      end
    end

    context "events" do
      let(:group) { groups(:bottom_group_one_two) }

      it "does not destroy exclusive events on soft destroy" do
        Fabricate(:event, groups: [group])
        expect { group.destroy }.not_to change(Event, :count)
      end

      it "destroys exclusive events on hard destroy" do
        Fabricate(:event, groups: [group])
        expect { group.really_destroy! }.to change { Event.count }.by(-1)
      end

      it "does not destroy events belonging to other groups as well" do
        Fabricate(:event, groups: [group, groups(:bottom_group_one_one)])
        expect { group.really_destroy! }.not_to change(Event, :count)
      end

      it "destroys event when removed from association" do
        expect { top_layer.events = [events(:top_event)] }.to change { Event.count }.by(-1)
      end
    end
  end

  context "contacts" do
    let(:contactable) do
      {street: "An der Foobar", housenumber: "23", zip_code: 3600, town: "thun", country: "ch"}
    end
    let(:group) { groups(:top_group) }

    subject { group }

    before { group.update!(contactable) }

    context "no contactable but contact info" do
      its(:contact) { should be_blank }
      its(:street) { should eq "An der Foobar" }
      its(:housenumber) { should eq "23" }
      its(:town) { should eq "thun" }
      its(:zip_code) { should eq 3600 }
      its(:country) { should eq "CH" }
    end

    context "discards contact info when contactable is set" do
      let(:contact) { Fabricate(:person, other_contactable) }
      let(:other_contactable) { {street: "barfoo", zip_code: nil} }
      let!(:other_contactable_role) do
        Fabricate(group.role_types.first.sti_name.to_sym, group: group, person: contact)
      end

      before do
        group.update_attribute(:contact, contact)
      end

      its(:street) { should eq "barfoo" }
      its(:zip_code?) { should be_falsey }
    end
  end

  context "invoice_config" do
    let(:parent) { groups(:top_layer) }

    it "is created for layer group" do
      group = Fabricate(Group::BottomLayer.sti_name, name: "g", parent: parent)
      expect(group.invoice_config).to be_present
    end

    it "is not created for non layer group" do
      group = Fabricate(Group::TopGroup.sti_name, name: "g", parent: parent)
      expect(group.invoice_config).not_to be_present
    end

    it "is destroyed group when group gets destroyed" do
      group = Fabricate(Group::BottomLayer.sti_name, name: "g", parent: parent)
      expect { group.destroy }.to change { InvoiceConfig.count }.by(-1)
    end
  end

  describe "e-mail validation" do
    let(:group) { groups(:top_layer) }

    before { allow(Truemail).to receive(:valid?).and_call_original }

    it "does not allow invalid e-mail address" do
      group.email = "blabliblu-ke-email"

      expect(group).not_to be_valid
      expect(group.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "allows blank e-mail address" do
      group.email = "   "

      expect(group).to be_valid
      expect(group.email).to be_nil
    end

    it "does not allow e-mail address with non-existing domain" do
      group.email = "group42@gitsäuäniä.it"

      expect(group).not_to be_valid
      expect(group.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "does not allow e-mail address with domain without mx record" do
      group.email = "dudes@bluewin.com"

      expect(group).not_to be_valid
      expect(group.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "does allow valid e-mail address" do
      group.email = "group42@puzzle.ch"

      expect(group).to be_valid
    end
  end

  describe "normalization" do
    let(:group) { groups(:top_layer) }

    it "downcases email" do
      group.email = "TesTer@gMaiL.com"
      expect(group.email).to eq "tester@gmail.com"
    end

    it "downcases self_registration_notification_email" do
      group.self_registration_notification_email = "TesTer@gMaiL.com"
      expect(group.self_registration_notification_email).to eq "tester@gmail.com"
    end
  end

  context "archived: " do
    subject(:archived_group) do
      groups(:bottom_group_one_two).tap { |g| g.update(archived_at: 1.day.ago) }
    end

    context "archived? is" do
      subject { groups(:bottom_group_one_two) }

      it "false without a date" do
        expect(subject.archived_at).to be_falsey

        is_expected.not_to be_archived
      end

      it "true with an archived_at date" do
        expect(archived_group.archived_at).to be_truthy

        expect(archived_group).to be_archived
      end

      it "making the group read-only" do
        expect(archived_group).to be_archived

        expect do
          archived_group.update!(name: "Followers of Blørbaël")
        end.to raise_error(ActiveRecord::ReadOnlyRecord)
      end

      it "still possible to delete" do
        expect(archived_group).to be_archived

        expect do
          archived_group.destroy
        end.to change { Group.without_deleted.count }.by(-1)
      end
    end

    context "archivable? is" do
      it "false when there are sub-groups" do
        group = groups(:top_layer)
        expect(group.children).to be_present

        expect(group).not_to be_archivable
      end

      it "false when already archived" do
        group = groups(:toppers).tap do |g|
          g.update(archived_at: 1.day.ago)
        end
        expect(group.children).to_not be_present

        expect(group).not_to be_archivable
      end

      it "true if there are no children" do
        group = groups(:toppers)
        expect(group.children).to_not be_present

        expect(group).to be_archivable
      end
    end

    context "archive!" do
      describe "roles" do
        let(:group) { groups(:top_group) }
        let(:role) { roles(:top_leader) }

        it "archives all roles with same timestamp" do
          group.archive!

          expect(group.reload).to be_archived
          expect(role).to be_archived
          expect(group.archived_at).to be_within(1.second).of(role.archived_at)
        end

        it "future roles are hard deleted" do
          Fabricate(group.role_types.first.sti_name.to_sym,
            person: role.person,
            group: group,
            start_on: 1.day.from_now)
          expect do
            group.archive!
          end.to change { group.roles.with_inactive.future.count }.by(-1)

          expect(group).to be_archived
        end
      end

      describe "mailing lists" do
        let(:group) { groups(:top_layer) }

        it "deletes all attached mailing lists" do
          expect(group.mailing_lists.size).to eq(2)

          expect do
            group.archive!
          end.to change { MailingList.count }.by(-2)

          expect(group.mailing_lists).to be_empty
        end

        it "deletes all attached subscriptions" do
          expect(group.subscriptions.size).to eq(1)

          expect do
            group.archive!
          end.to change { Subscription.count }.by(-1)

          expect(group.subscriptions).to be_empty
        end
      end
    end

    context "soft-deletion" do
      it "is supported" do
        expect(archived_group.class.ancestors).to include(Paranoia)

        expect do
          archived_group.destroy!
        end.to change { Group.without_deleted.count }.by(-1)

        expect(archived_group.reload.deleted_at).to_not be_nil
      end
    end
  end

  context "integrates with nextcloud, it" do
    subject { groups(:top_layer) }

    it "has a nextcloud_url" do
      subject.nextcloud_url = "https://example.org"
      subject.save!
      subject.reload

      expect(subject.nextcloud_url).to eql "https://example.org"
    end

    it "has the nextcloud_url" do
      expect(described_class.used_attributes).to include(:nextcloud_url)
      expect(subject.used_attributes).to include(:nextcloud_url)
    end
  end

  context "mounted attributes" do
    let(:top_layer) { groups(:top_layer) }

    it "saves attribute for specific group type" do
      top_layer.foundation_year = 1892
      top_layer.custom_name = "Töp"

      expect do
        top_layer.save!
      end.to change { MountedAttribute.count }.by(2)

      top_layer.reload

      expect(top_layer.foundation_year).to eq(1892)
      expect(top_layer.custom_name).to eq("Töp")
    end

    it "does not persists attribute entry if default value" do
      # 1942 is configured default value for foundation_year
      expect(top_layer.foundation_year).to eq(1942)

      expect do
        top_layer.save!
      end.not_to(change { MountedAttribute.count })

      expect(top_layer.foundation_year).to eq(1942)
    end

    it "does not persist attribute entry if nil value" do
      top_layer.custom_name = nil

      expect do
        top_layer.save!
      end.not_to(change { MountedAttribute.count })

      top_layer.reload

      expect(top_layer.custom_name).to be_blank
      expect(top_layer.foundation_year).to eq(1942)
    end

    it "does not persist attribute entry if validation error for mounted attribute" do
      top_layer.foundation_year = 300

      expect do
        top_layer.save
      end.not_to(change { MountedAttribute.count })

      expect(top_layer.errors).to be_present
      expect(top_layer.errors.first.message).to eq("muss grösser als 1850 sein")
    end

    it "only allows value defined in enum" do
      top_layer.shirt_size = "ns"

      expect do
        top_layer.save
      end.not_to(change { MountedAttribute.count })

      expect(top_layer.errors).to be_present
      expect(top_layer.errors.first.message).to eq("ist kein gültiger Wert")

      top_layer.shirt_size = "l"

      expect do
        top_layer.save!
      end.to change { MountedAttribute.count }.by(1)

      top_layer.reload
      expect(top_layer.shirt_size).to eq("l")
    end

    it "returns mounted attr configs by category" do
      configs_by_category = top_layer.class.mounted_attr_configs_by_category
      expect(configs_by_category.keys).to eq([:custom_cat, :default])

      default_attr_names = configs_by_category[:default].collect(&:attr_name)
      expect(default_attr_names).to include(:foundation_year)
      expect(default_attr_names).to include(:shirt_size)

      custom_cat_attr_names = configs_by_category[:custom_cat].collect(&:attr_name)
      expect(custom_cat_attr_names).to include(:custom_name)
    end
  end

  context "encrypted attributes" do
    it "can be blank" do
      group = groups(:top_layer)
      group.encrypted_text_message_username = ""

      expect(group.text_message_username).to be_empty
    end
  end

  context "name" do
    let(:group) { groups(:bottom_layer_one) }

    context "with static_name=false" do
      before { group.static_name = false }

      it "#name returns name" do
        expect(group.name).to eq "Bottom One"
      end

      it "#name= sets name" do
        expect { group.name = "Another Name" }
          .to change { group.read_attribute(:name) }.to("Another Name")
      end
    end

    context "with static_name=true" do
      before { group.static_name = true }
      after { group.static_name = false }

      it "#name returns class label" do
        expect(group.name).to eq "Bottom Layer"
      end

      it "#name= noops" do
        expect { group.name = "Another Name" }
          .not_to(change { group.read_attribute(:name) })
      end
    end
  end

  context "type" do
    let(:duplicate) { group.dup }

    context "with static_name=false" do
      let(:group) { groups(:bottom_group_two_one) }

      it "uniqueness is not validated" do
        duplicate.validate
        expect(duplicate.errors[:type]).to be_empty
      end
    end

    context "with static_name=true" do
      let(:group) { Fabricate(Group::StaticNameAGroup.name, parent: groups(:bottom_layer_one)) }

      it "uniqueness is validated for same parent_id" do
        duplicate.validate
        expect(duplicate.errors[:type]).to include("ist bereits vergeben")
      end

      it "uniqueness is not validated for different parent_id" do
        duplicate.parent_id = 99_999
        duplicate.validate
        expect(duplicate.errors[:type]).to be_empty
      end
    end
  end

  context "addable_child_types" do
    let(:group) { Fabricate(Group::BottomLayer.name) }

    context "when no children exist" do
      it "returns possible_children" do
        expect(group.addable_child_types).to contain_exactly(
          Group::BottomGroup, Group::MountedAttrsGroup, Group::GlobalGroup,
          Group::StaticNameAGroup, Group::StaticNameBGroup
        )
      end
    end

    context "when children without static_name exist" do
      it "when children exist returns possible_children" do
        Fabricate(Group::BottomGroup.name, parent: group)
        expect(group.addable_child_types).to contain_exactly(
          Group::BottomGroup, Group::MountedAttrsGroup, Group::GlobalGroup,
          Group::StaticNameAGroup, Group::StaticNameBGroup
        )
      end
    end

    context "when only deleted children with static_name exist" do
      it "returns possible_children" do
        Fabricate(Group::StaticNameAGroup.name, parent: group, deleted_at: 1.day.ago)
        expect(group.addable_child_types).to contain_exactly(
          Group::BottomGroup, Group::MountedAttrsGroup, Group::GlobalGroup,
          Group::StaticNameAGroup, Group::StaticNameBGroup
        )
      end
    end

    context "when children with static_name exist" do
      it "returns possible_children minus existing child types" do
        Fabricate(Group::StaticNameAGroup.name, parent: group)
        expect(group.addable_child_types).to contain_exactly(
          Group::BottomGroup, Group::MountedAttrsGroup, Group::GlobalGroup,
          Group::StaticNameBGroup
        )
      end
    end
  end

  context "rebuild!" do
    context "with archived group" do
      let(:group) { groups(:bottom_group_one_two) }

      before do
        group.tap { |g| g.update(archived_at: 1.day.ago) }
      end

      it "allows to adjust parent and rebuild with validations" do
        group.update(parent_id: groups(:bottom_layer_two).id)

        expect do
          Group.rebuild!
        end.to_not raise_error
      end

      it "allows to adjust parent and rebuild without validations" do
        group.update(parent_id: groups(:bottom_layer_two).id)

        expect do
          Group.rebuild!(false)
        end.to_not raise_error
      end
    end
  end
end
