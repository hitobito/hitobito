# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  archived_at :datetime
#  end_on      :date
#  label       :string(255)
#  start_on    :date
#  terminated  :boolean          default(FALSE), not null
#  type        :string(255)      not null
#  created_at  :datetime
#  updated_at  :datetime
#  group_id    :integer          not null
#  person_id   :integer          not null
#
# Indexes
#
#  index_roles_on_person_id_and_group_id  (person_id,group_id)
#  index_roles_on_type                    (type)
#

require "spec_helper"

describe Role do
  context "validates" do
    let(:group) { groups(:bottom_layer_one) }
    let(:today) { Time.zone.today }
    let(:yesterday) { Time.zone.yesterday }
    let(:tomorrow) { Time.zone.tomorrow }

    subject(:error_messages) { role.errors.full_messages }

    subject(:role) { Fabricate.build(:"Group::BottomLayer::Leader", group: group) }

    it "is valid when start_on and end_on are blank" do
      role.attributes = {start_on: nil, end_on: nil}
      is_expected.to be_valid
    end

    it "is valid when start_on is set and end_on is blank" do
      role.attributes = {start_on: yesterday, end_on: nil}
      is_expected.to be_valid
    end

    it "is valid when start_on is blank and end_on is set" do
      role.attributes = {start_on: nil, end_on: tomorrow}
      is_expected.to be_valid
    end

    it "is valid when start_on is before end_on" do
      role.attributes = {start_on: yesterday, end_on: tomorrow}
      is_expected.to be_valid
    end

    it "is valid when start_on is equal to end_on" do
      role.attributes = {start_on: today, end_on: today}
      is_expected.to be_valid
    end

    it "is invalid when start_on is after end_on" do
      role.attributes = {start_on: tomorrow, end_on: yesterday}
      is_expected.not_to be_valid
      expect(error_messages).to include("Bis kann nicht vor Von sein")
    end
  end

  context "scopes" do
    let(:role) { roles(:top_leader) }

    it "default scope is same as active" do
      expect(Role.all.to_sql).to eq(Role.active.to_sql)
    end

    describe ":active" do
      it "includes roles without start_on and end_on" do
        expect(role.start_on).to be_nil
        expect(role.end_on).to be_nil
        expect(Role.active).to include role
      end

      it "includes roles with start_on is in the past" do
        role.update!(start_on: Date.current.yesterday)
        expect(Role.active).to include(role)
      end

      it "includes roles with start_on is today" do
        role.update!(start_on: Date.current)
        expect(Role.active).to include(role)
      end

      it "excludes roles with start_on is in the future" do
        role.update!(start_on: Date.current.tomorrow)
        expect(Role.active).not_to include(role)
      end

      it "can query with custom reference date" do
        role.update!(start_on: Date.current.tomorrow)
        expect(Role.active(Date.current)).not_to include(role)
        expect(Role.active(Date.current.tomorrow)).to include(role)
      end
    end

    describe ":with_inactive" do
      it "includes ended roles" do
        role.update!(end_on: Date.current.yesterday)
        expect(Role.with_inactive).to include role
      end

      it "includes future roles" do
        role.update!(start_on: Date.current.tomorrow)
        expect(Role.with_inactive).to include role
      end

      it "includes archived roles" do
        role.update!(archived_at: Time.current)
        expect(Role.with_inactive).to include role
      end
    end

    describe ":inactive" do
      it "excludes roles without end_on and archived_at" do
        expect(role.end_on).to be_nil
        expect(role.archived_at).to be_nil
        expect(Role.inactive).not_to include role
      end

      it "excludes roles with end_on is in the future" do
        role.update!(end_on: Date.current.tomorrow)
        expect(Role.inactive).not_to include role
      end

      it "excludes roles with end_on is today" do
        role.update!(end_on: Date.current)
        expect(Role.inactive).not_to include role
      end

      it "excludes roles with archived_at is in the future" do
        role.update!(archived_at: 10.minutes.from_now)
        expect(Role.inactive).not_to include role
      end

      it "includes roles with end_on is in the past" do
        role.update!(end_on: Date.current.yesterday)
        expect(Role.inactive).to include role
      end

      it "includes roles with archived_at is in the past" do
        role.update!(archived_at: 10.minutes.ago)
        expect(Role.inactive).to include role
      end
    end

    describe ":without_archived" do
      it "excludes roles with archived_at" do
        role.update!(archived_at: Time.current)
        expect(Role.without_archived).not_to include role
      end

      it "excludes roles with archived_at is in the future" do
        role.update!(archived_at: 10.minutes.from_now)
        expect(Role.without_archived).not_to include
      end

      it "includes roles without archived_at" do
        expect(role.archived_at).to be_nil
        expect(Role.without_archived).to include role
      end
    end

    describe ":only_archived" do
      it "excludes roles without archived_at" do
        expect(role.archived_at).to be_nil
        expect(Role.only_archived).not_to include role
      end

      it "includes roles with archived_at" do
        role.update!(archived_at: Time.current)
        expect(Role.only_archived).to include role
      end

      it "excludes roles with archived_at is in the future" do
        role.update!(archived_at: 10.minutes.from_now)
        expect(Role.only_archived).not_to include role
      end
    end

    describe ":future" do
      it "excludes roles without start_on" do
        expect(role.start_on).to be_nil
        expect(Role.future).not_to include role
      end

      it "excludes roles with start_on is in the past" do
        role.update!(start_on: Date.current.yesterday)
        expect(Role.future).not_to include role
      end

      it "excludes roles with start_on is today" do
        role.update!(start_on: Date.current)
        expect(Role.future).not_to include role
      end

      it "includes roles with start_on is in the future" do
        role.update!(start_on: Date.current.tomorrow)
        expect(Role.future).to include role
      end
    end

    describe ":ended" do
      it "excludes roles without end_on" do
        expect(role.end_on).to be_nil
        expect(Role.ended).not_to include role
      end

      it "excludes roles with end_on is in the future" do
        role.update!(end_on: Date.current.tomorrow)
        expect(Role.ended).not_to include role
      end

      it "excludes roles with end_on is today" do
        role.update!(end_on: Date.current)
        expect(Role.ended).not_to include role
      end

      it "includes roles with end_on is in the past" do
        role.update!(end_on: Date.current.yesterday)
        expect(Role.ended).to include role
      end
    end
  end

  context "class" do
    subject { described_class }

    its(:all_types) { should have(17).items }

    its(:visible_types) { should have(15).items }

    its(:visible_types) { should_not include(Group::BottomGroup::Member) }

    its(:terminatable) { should eq false }

    it "should have two types with permission :layer_and_below_full" do
      expect(described_class.types_with_permission(:layer_and_below_full).to_set)
        .to eq([Group::TopGroup::Leader, Group::BottomLayer::Leader].to_set)
    end

    it "should have no types with permission :not_existing" do
      expect(described_class.types_with_permission(:not_existing)).to be_empty
    end
  end

  context "regular" do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:bottom_layer_one) }

    subject do
      r = described_class.new # Group::BottomLayer::Leader.new
      r.type = "Group::BottomLayer::Leader"
      r.person = person
      r.group = group
      r
    end

    context "type" do
      it "is invalid without type" do
        subject.type = nil
        is_expected.to have(1).errors_on(:type)
      end

      it "is invalid with non-existing type" do
        subject.type = "Foo"
        is_expected.to have(1).errors_on(:type)
      end

      it "is invalid with type from other group" do
        subject.type = "Group::TopGroup::Leader"
        is_expected.to have(1).errors_on(:type)
      end

      it "is valid with allowed type" do
        subject.type = "Group::BottomLayer::Leader"
        is_expected.to be_valid
      end
    end

    context "primary group" do
      # before { subject.type = 'Group::BottomLayer::Leader' }

      it "is set for first role" do
        expect(subject.save).to be_truthy
        expect(person.primary_group_id).to eq(group.id)
      end

      it "is not set on subsequent roles" do
        Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
        subject.save
        expect(person.primary_group_id).not_to eq(group.id)
      end

      it "is reset if persons last role is destroyed" do
        subject.save
        expect(subject.destroy).to be_truthy
        expect(person.primary_group_id).to be_nil
      end

      it "is reset to remaining role if role is destroyed" do
        subject.save
        Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
        expect(subject.destroy).to be_truthy
        expect(person.primary_group).to eq groups(:top_group)
      end

      it "is reset to newest remaining role if role is destroyed" do
        subject.save
        role2 = Fabricate(Group::GlobalGroup::Leader.name.to_s, person: person,
          group: groups(:toppers))
        role3 = Fabricate(Group::TopGroup::Leader.name.to_s, person: person,
          group: groups(:top_group))
        role3.update_attribute(:updated_at, Time.zone.today - 10.days)
        expect(subject.destroy).to be_truthy
        expect(person.primary_group).to eq role2.group
      end

      it "is not reset if role is destroyed and other roles in the same group exist" do
        Fabricate(Group::BottomLayer::Member.name.to_s, person: person, group: group)
        subject.save
        expect(subject.destroy).to be_truthy
        expect(person.primary_group_id).to eq(group.id)
      end

      it "is reset if role is destroyed and primary group does not exist" do
        subject.save
        person.update_column :primary_group_id, 42
        expect(subject.destroy).to be_truthy
        expect(person.primary_group_id).to be_nil
      end
    end

    context "contact data callback" do
      it "sets contact data flag on person" do
        subject.type = "Group::BottomLayer::Leader"
        subject.save!
        expect(person).to be_contact_data_visible
      end

      it "sets contact data flag on person with flag" do
        person.update_attribute :contact_data_visible, true
        subject.type = "Group::BottomLayer::Leader"
        subject.save!
        expect(person).to be_contact_data_visible
      end

      it "removes contact data flag on person " do
        person.update_attribute :contact_data_visible, true
        subject.type = "Group::BottomLayer::Leader"
        subject.save!

        role = described_class.find(subject.id) # reload from db to get the correct class
        role.destroy

        expect(person.reload).not_to be_contact_data_visible
      end

      it "does not remove contact data flag on person when other roles exist" do
        Fabricate(Group::TopGroup::Member.name.to_s, group: groups(:top_group), person: person)
        subject.type = "Group::BottomLayer::Leader"
        subject.save!

        role = described_class.find(subject.id) # reload from db to get the correct class
        role.destroy

        expect(person.reload).to be_contact_data_visible
      end
    end
  end

  context ".normalize_label" do
    it "reuses existing label" do
      a1 = Fabricate(Group::BottomLayer::Leader.name.to_s, label: "foo",
        group: groups(:bottom_layer_one))
      a2 = Fabricate(Group::BottomLayer::Leader.name.to_s, label: "fOO",
        group: groups(:bottom_layer_one))
      expect(a2.label).to eq(a1.label)
    end
  end

  context "#to_s" do
    let(:group) { groups(:bottom_layer_one) }
    let(:date) { Date.new(2023, 11, 15) }

    def build_role(attrs = {})
      Fabricate.build(Group::BottomLayer::Leader.sti_name, attrs.merge(group: group))
    end

    it "includes group specific role type" do
      expect(build_role.to_s).to eq "Leader"
    end

    it "appends label if set" do
      expect(build_role(label: "test").to_s).to eq "Leader (test)"
    end

    it "appends end_on if set" do
      expect(build_role(end_on: date).to_s).to eq "Leader (bis 15.11.2023)"
    end

    it "combines label and end_on if both are set" do
      expect(build_role(label: "test", end_on: date).to_s).to eq "Leader (test) (bis 15.11.2023)"
    end
  end

  context "#available_labels" do
    before { described_class.sweep_available_labels }

    subject { Group::BottomLayer::Leader.available_labels }

    it "includes labels from database" do
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: "foo",
        group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: "FOo",
        group: groups(:bottom_layer_one))
      is_expected.to eq(["foo"])
    end

    it "includes labels from all types" do
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: "foo",
        group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::Member.name.to_s, label: "Bar",
        group: groups(:bottom_layer_one))
      is_expected.to eq(%w[Bar foo])
    end
  end

  context "#create" do
    let(:person) { people(:top_leader) }

    it "nullifies minimized_at of person" do
      person.update!(minimized_at: Time.zone.now)
      expect(person.minimized_at).to be_present

      Group::TopGroup::Member.create!(person: person, group: groups(:top_group))

      person.reload

      expect(person.minimized_at).to be_nil
    end
  end

  context "#destroy" do
    context "on young role" do
      let(:role) do
        Fabricate(Group::BottomLayer::Leader.name.to_s, group: groups(:bottom_layer_one))
      end

      it "gets deleted from database" do
        role.destroy
        expect(described_class.unscoped.where(id: role.id)).not_to be_exists
      end

      it "with always_soft_destroy: true ends role per yesterday" do
        expect { role.destroy(always_soft_destroy: true) }
          .to change { role.reload.end_on }.to(Date.current.yesterday)
      end

      it "triggers destroy callback" do
        expect(role).to receive(:set_contact_data_visible)
        role.destroy
      end
    end

    context "on role ended in the past" do
      let(:role) do
        Fabricate(Group::BottomLayer::Leader.name.to_s,
          end_on: Date.current.last_year,
          group: groups(:bottom_layer_one))
      end

      it "does not change end_on" do
        expect { role.destroy(always_soft_destroy: true) }
          .not_to change { role.reload.end_on }
      end
    end

    context "on old role" do
      let(:role) do
        Fabricate(Group::BottomLayer::Leader.name.to_s,
          created_at: Time.zone.now - Settings.role.minimum_days_to_archive.days - 1.day,
          group: groups(:bottom_layer_one))
      end

      it "ends role per yesterday" do
        expect { role.destroy }.to change { role.reload.end_on }.to(Date.current.yesterday)
      end

      it "does triggers destroy callback" do
        expect(role).to receive(:set_contact_data_visible)
        role.destroy
      end
    end
  end

  context "#destroy!" do
    it "soft deletes young roles with always_soft_destroy: true" do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: "foo",
        group: groups(:bottom_layer_one))

      expect { a.destroy!(always_soft_destroy: true) }
        .to change { a.reload.end_on }.to(Date.current.yesterday)
    end
  end

  context "#ended?" do
    it "is false if end_on is nil" do
      expect(Role.new).not_to be_ended
    end

    it "is false if end_on is in the future" do
      expect(Role.new(end_on: 1.day.from_now)).not_to be_ended
    end

    it "is false if end_on is today" do
      expect(Role.new(end_on: Time.zone.today)).not_to be_ended
    end

    it "is true if end_on is in the past" do
      expect(Role.new(end_on: 1.day.ago)).to be_ended
    end
  end

  context "#in_primary_group?" do
    let(:role) { roles(:bottom_member) }

    it "is true if role is in primary group" do
      role.person.update!(primary_group: role.group)
      expect(role.in_primary_group?).to eq true
    end

    it "is false if role is not in primary group" do
      role.person.update!(primary_group: groups(:top_group))
      expect(role.in_primary_group?).to eq false
    end
  end

  context "#label_long adds group to role" do
    subject { role.label_long }

    context "group with long key" do
      let(:role) { Group::BottomLayer::Leader }

      it { is_expected.to eq "Leader Bottom Layer Long" }
    end

    context "group without long key" do
      let(:role) { Group::BottomGroup::Leader }

      it { is_expected.to eq "Leader Bottom Group" }
    end
  end

  context "#terminated" do
    it "can not be assigned directly" do
      role = Role.new
      expect { role.terminated = true }.to raise_error(/do not set terminated directly/)
    end

    it "can not be updated directly" do
      role = roles(:bottom_member)
      expect { role.update!(terminated: true) }.to raise_error(/do not set terminated directly/)
    end
  end

  context "#terminatable?" do
    let(:role_class) { Class.new(Role) }

    context "when ::terminatable=false" do
      it "is false by default" do
        assert !role_class.terminatable
        expect(role_class.new.terminatable?).to eq false
      end
    end

    context "when ::terminatable=true" do
      before { role_class.terminatable = true }

      it "is true" do
        expect(role_class.new.terminatable?).to eq true
      end

      it "is false if role is terminated" do
        role = role_class.new.tap { |r| r.write_attribute(:terminated, true) }
        expect(role.terminatable?).to eq false
      end

      it "is false if role is archived" do
        role = role_class.new(archived_at: 1.day.from_now)
        expect(role.terminatable?).to eq false
      end
    end
  end

  context "#terminated_on" do
    def role(**attrs)
      terminated = attrs.delete(:terminated) || false
      Role.new(attrs.reverse_merge(end_on: nil)).tap do |r|
        r.write_attribute(:terminated, terminated)
      end
    end

    it "returns nil if role is not terminated" do
      expect(role.terminated_on).to be_nil
    end

    it "returns end_on if role is terminated" do
      date = 1.day.from_now.to_date
      expect(role(terminated: true, end_on: date).terminated_on).to eq date
    end

    it "returns end_on if role is terminated" do
      date = 1.day.from_now.to_date
      expect(role(terminated: true, end_on: date).terminated_on).to eq date
    end
  end

  context "paper trails", versioning: true do
    let(:person) { people(:top_leader) }

    it "sets main on create" do
      expect do
        role = person.roles.build
        role.group = groups(:top_group)
        role.type = Group::TopGroup::Leader.sti_name
        role.save!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(person)
    end

    it "sets main on update" do
      role = person.roles.first
      expect do
        role.update!(label: "Foo")
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("update")
      expect(version.main).to eq(person)
    end

    context "on destroy" do
      it "with role too young to archive" do
        role = person.roles.first
        expect(role.created_at).to be > Settings.role.minimum_days_to_archive.days.ago

        expect do
          role.destroy!
        end.not_to change { PaperTrail::Version.count }
      end

      it "with role old enough to archive" do
        role = person.roles.first
        role.created_at = Settings.role.minimum_days_to_archive.days.ago - 1.second

        expect do
          role.destroy!
        end.to change { PaperTrail::Version.count }.by(1)

        version = PaperTrail::Version.order(:created_at, :id).last
        expect(version.event).to eq("update")
        expect(version.main).to eq(person)
      end
    end
  end

  context "archived:" do
    around do |spec|
      previous = Settings.role.minimum_days_to_archive
      Settings.role.minimum_days_to_archive = 0

      spec.run

      Settings.role.minimum_days_to_archive = previous || 7
    end

    subject(:archived_role) do
      roles(:bottom_member).tap { |r| r.update(archived_at: 1.day.ago) }
    end

    context "archived? is" do
      subject { roles(:bottom_member) }

      it "false without a date" do
        expect(subject.archived_at).to be_falsey

        is_expected.not_to be_archived
      end

      it "true with an archived_at date" do
        expect(archived_role.archived_at).to be_truthy

        expect(archived_role).to be_archived
      end

      it "making the role read-only" do
        expect(archived_role).to be_archived

        expect do
          archived_role.update!(label: "Follower of Blørbaël")
        end.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end
  end

  context "nextcloud groups" do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:bottom_layer_one) }
    let(:nextcloud_group_mapping) { false }

    subject do
      r = described_class.new # Group::BottomLayer::Leader.new
      r.class.nextcloud_group = nextcloud_group_mapping
      r.type = "Group::BottomLayer::Leader"
      r.person = person
      r.group = group
      r
    end

    after do
      subject.class.nextcloud_group = false
    end

    it "have assumptions" do
      expect(Settings.groups.nextcloud.enabled).to be true # in the test-env
    end

    describe "role without mapping" do
      let(:nextcloud_group_mapping) { false }

      it "has a value of false" do
        expect(subject.class.nextcloud_group).to be false
      end

      it "does not return any nextcloud groups" do
        expect(subject.nextcloud_group).to be_nil
      end
    end

    describe "role with constant mapping" do
      let(:nextcloud_group_mapping) { "Admins" }

      it "has a String-value" do
        expect(subject.class.nextcloud_group).to eq "Admins"
      end

      it "does not return any nextcloud groups" do
        expect(subject.nextcloud_group.to_h).to eq(
          "gid" => "hitobito-Admins",
          "displayName" => "Admins"
        )
      end
    end

    describe "role with dynamic mapping" do
      let(:nextcloud_group_mapping) { true }
      let(:group) do
        Group::GlobalGroup.new(id: 1024, name: "Test", parent: groups(:top_layer))
      end

      it "has a value of false" do
        expect(subject.class.nextcloud_group).to be true
      end

      it "does not return any nextcloud groups" do
        expect(subject.nextcloud_group.to_h).to eq(
          "gid" => "1024",
          "displayName" => "Test"
        )
      end
    end

    describe "role with a method mapping" do
      let(:nextcloud_group_mapping) { :my_nextcloud_group }

      before do
        subject.define_singleton_method :my_nextcloud_group do
          {"gid" => "1234", "displayName" => "TestGruppe"}
        end
      end

      it "has a Symbol as value" do
        expect(subject.class.nextcloud_group).to be_a Symbol
      end

      it "responds to the method" do
        is_expected.to respond_to :my_nextcloud_group
      end

      it "delegates to the other group" do
        expect(subject.nextcloud_group.to_h).to eq(
          "gid" => "1234",
          "displayName" => "TestGruppe"
        )
      end
    end

    describe "role with a proc mapping" do
      let(:nextcloud_group_mapping) do
        proc do |role|
          {
            "gid" => role.type,
            "displayName" => role.class.name.humanize
          }
        end
      end

      it "has a Symbol as value" do
        expect(subject.class.nextcloud_group).to be_a Proc
      end

      it "delegates to the Proc" do
        expect(subject.nextcloud_group.to_h).to eq(
          "gid" => "Group::BottomLayer::Leader",
          "displayName" => "Role"
        )
      end
    end
  end
end
