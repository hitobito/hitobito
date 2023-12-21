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
#  convert_on  :date
#  convert_to  :string(255)
#  delete_on   :date
#  deleted_at  :datetime
#  label       :string(255)
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

require 'spec_helper'

describe Role do

  context 'validates' do
    let(:group) { groups(:bottom_layer_one) }
    let(:today) { Time.zone.today }
    let(:yesterday) { Time.zone.yesterday }
    let(:tomorrow) { Time.zone.tomorrow }
    subject(:error_messages) { role.errors.full_messages }

    context 'new record' do
      subject(:role) { Fabricate.build(:'Group::BottomLayer::Leader', group: group) }

      it 'is valid without created_at or delete_on attrs' do
        expect(role).to be_valid
      end

      describe 'created_at' do
        it 'is valid if in the past' do
          role.created_at = yesterday
          expect(role).to be_valid
        end

        it 'is valid if today' do
          role.created_at = today
          expect(role).to be_valid
        end

        it 'is invalid if in the future' do
          role.created_at = tomorrow
          expect(role).to have(1).error_on(:created_at)
          expect(error_messages).to eq ['Von kann nicht später als heute sein']
        end
      end

      describe 'delete_on' do
        it 'is invalid if before created_at' do
          role.created_at = today
          role.delete_on = yesterday
          expect(role).to have(1).error_on(:delete_on)
          expect(error_messages).to eq ['Bis kann nicht vor Von sein']
        end

        it 'is valid if today' do
          role.created_at = today
          role.delete_on = today
          expect(role).to be_valid
        end

        it 'is valid if in the future' do
          role.created_at = yesterday
          role.delete_on = tomorrow
          expect(role).to be_valid
        end

        it 'is valid if blank' do
          role.created_at = yesterday
          role.delete_on = ''
          expect(role).to be_valid
        end
      end
    end

    context 'persisted record' do
      let(:role) { roles(:top_leader) }

      it 'is valid if created_at is in the past' do
        role.created_at = yesterday
        expect(role).to be_valid
      end

      it 'is valid if created_at and delete_on are in past' do
        role.created_at = yesterday - 1.day
        role.delete_on = yesterday
        expect(role).to be_valid
      end

      it 'is invalid if created_at and delete_on are in past but twisted' do
        role.created_at = yesterday
        role.delete_on = yesterday - 1.day
        expect(role).to have(1).error_on(:delete_on)
        expect(error_messages).to eq ['Bis kann nicht vor Von sein']
      end

      it 'is invalid if created_at is in the future' do
        role.created_at = tomorrow
        expect(role).to have(1).error_on(:created_at)
        expect(error_messages).to eq ['Von kann nicht später als heute sein']
      end

      it 'is invalid if delete_on is before created_at' do
        role.delete_on = (role.created_at - 1.day).noon
        expect(role).to have(1).error_on(:delete_on)
        expect(error_messages).to eq ['Bis kann nicht vor Von sein']
      end

      it 'is invalid if delete_on is before created_at and both are in the future' do
        role.delete_on = tomorrow + 1.day
        role.created_at = tomorrow
        expect(role).to have(0).error_on(:delete_on)
        expect(role).to have(1).error_on(:created_at)
        expect(error_messages).to eq ['Von kann nicht später als heute sein']
      end

      it 'is invalid if delete_on is before created_at and both are in the future' do
        role.delete_on = tomorrow + 1.day
        role.created_at = tomorrow + 2.days
        expect(role).to have(0).error_on(:delete_on)
        expect(role).to have(1).error_on(:created_at)
        expect(error_messages).to eq ['Von kann nicht später als heute sein']
      end
    end
  end

  describe '::inactive scope' do
    subject(:inactive) { Role.inactive }

    it 'excludes active roles' do
      expect(inactive).to be_empty
    end

    it 'includes deleted roles' do
      roles(:bottom_member).update(deleted_at: 1.day.ago)
      expect(inactive).to have(1).item
    end

    it 'includes archived roles from the past' do
      roles(:bottom_member).update(archived_at: 3.days.ago)
      expect(inactive).to have(1).item
    end

    it 'excludes archived roles from the future' do
      roles(:bottom_member).update(archived_at: 3.days.from_now)
      expect(inactive).to be_empty
    end
  end

  context 'class' do
    subject { described_class }

    its(:all_types) { should have(16).items }

    its(:visible_types) { should have(14).items }

    its(:visible_types) { should_not include(Group::BottomGroup::Member) }

    its(:terminatable) { should eq false }

    it 'should have two types with permission :layer_and_below_full' do
      expect(described_class.types_with_permission(:layer_and_below_full).to_set)
        .to eq([Group::TopGroup::Leader, Group::BottomLayer::Leader].to_set)
    end

    it 'should have no types with permission :not_existing' do
      expect(described_class.types_with_permission(:not_existing)).to be_empty
    end
  end

  context 'regular' do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:bottom_layer_one) }
    subject do
      r = described_class.new # Group::BottomLayer::Leader.new
      r.type = 'Group::BottomLayer::Leader'
      r.person = person
      r.group = group
      r
    end

    context 'type' do
      it 'is invalid without type' do
        subject.type = nil
        is_expected.to have(1).errors_on(:type)
      end

      it 'is invalid with non-existing type' do
        subject.type = 'Foo'
        is_expected.to have(1).errors_on(:type)
      end

      it 'is invalid with type from other group' do
        subject.type = 'Group::TopGroup::Leader'
        is_expected.to have(1).errors_on(:type)
      end

      it 'is valid with allowed type' do
        subject.type = 'Group::BottomLayer::Leader'
        is_expected.to be_valid
      end
    end

    context 'primary group' do
      # before { subject.type = 'Group::BottomLayer::Leader' }

      it 'is set for first role' do
        expect(subject.save).to be_truthy
        expect(person.primary_group_id).to eq(group.id)
      end

      it 'is not set on subsequent roles' do
        Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
        subject.save
        expect(person.primary_group_id).not_to eq(group.id)
      end

      it 'is reset if persons last role is destroyed' do
        subject.save
        expect(subject.destroy).to be_truthy
        expect(person.primary_group_id).to be_nil
      end

      it 'is reset to remaining role if role is destroyed' do
        subject.save
        Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
        expect(subject.destroy).to be_truthy
        expect(person.primary_group).to eq groups(:top_group)
      end

      it 'is reset to newest remaining role if role is destroyed' do
        subject.save
        role2 = Fabricate(Group::GlobalGroup::Leader.name.to_s, person: person,
                                                                group: groups(:toppers))
        role3 = Fabricate(Group::TopGroup::Leader.name.to_s, person: person,
                                                             group: groups(:top_group))
        role3.update_attribute(:updated_at, Time.zone.today - 10.days)
        expect(subject.destroy).to be_truthy
        expect(person.primary_group).to eq role2.group
      end

      it 'is not reset if role is destroyed and other roles in the same group exist' do
        Fabricate(Group::BottomLayer::Member.name.to_s, person: person, group: group)
        subject.save
        expect(subject.destroy).to be_truthy
        expect(person.primary_group_id).to eq(group.id)
      end

      it 'is not reset if role is destroyed and primary group is another group' do
        subject.save
        person.update_column :primary_group_id, 42
        expect(subject.destroy).to be_truthy
        expect(person.primary_group_id).to eq(42)
      end

    end

    context 'contact data callback' do

      it 'sets contact data flag on person' do
        subject.type = 'Group::BottomLayer::Leader'
        subject.save!
        expect(person).to be_contact_data_visible
      end

      it 'sets contact data flag on person with flag' do
        person.update_attribute :contact_data_visible, true
        subject.type = 'Group::BottomLayer::Leader'
        subject.save!
        expect(person).to be_contact_data_visible
      end

      it 'removes contact data flag on person ' do
        person.update_attribute :contact_data_visible, true
        subject.type = 'Group::BottomLayer::Leader'
        subject.save!

        role = described_class.find(subject.id)  # reload from db to get the correct class
        role.destroy

        expect(person.reload).not_to be_contact_data_visible
      end

      it 'does not remove contact data flag on person when other roles exist' do
        Fabricate(Group::TopGroup::Member.name.to_s, group: groups(:top_group), person: person)
        subject.type = 'Group::BottomLayer::Leader'
        subject.save!

        role = described_class.find(subject.id)  # reload from db to get the correct class
        role.destroy

        expect(person.reload).to be_contact_data_visible
      end
    end
  end

  context '.normalize_label' do
    it 'reuses existing label' do
      a1 = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo',
                                                           group: groups(:bottom_layer_one))
      a2 = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'fOO',
                                                           group: groups(:bottom_layer_one))
      expect(a2.label).to eq(a1.label)
    end
  end

  context '#to_s' do
    let(:group) { groups(:bottom_layer_one) }
    let(:date) { Date.new(2023, 11, 15) }

    def build_role(attrs = {})
      Fabricate.build(Group::BottomLayer::Leader.sti_name, attrs.merge(group: group))
    end

    it 'includes group specific role type' do
      expect(build_role.to_s).to eq 'Leader'
    end

    it 'appends label if set' do
      expect(build_role(label: 'test').to_s).to eq 'Leader (test)'
    end

    it 'appends delete_on if set' do
      expect(build_role(delete_on: date).to_s).to eq 'Leader (bis 15.11.2023)'
    end

    it 'combines label and delete_on if both are set' do
      expect(build_role(label: 'test', delete_on: date).to_s).to eq 'Leader (test) (bis 15.11.2023)'
    end
  end

  context '#outdated?' do
    let(:group) { groups(:bottom_layer_one) }

    let(:today) { Time.zone.today }
    let(:yesterday) { Time.zone.yesterday }
    let(:tomorrow) { Time.zone.tomorrow }

    def build_role(attrs = {})
      Fabricate.build(Group::BottomLayer::Leader.sti_name, attrs.merge(group: group))
    end

    it 'is not outdated by default' do
      expect(build_role).not_to be_outdated
    end

    it 'is outdated if convert_on is today or earlier' do
      expect(build_role(convert_on: tomorrow)).not_to be_outdated
      expect(build_role(convert_on: yesterday)).to be_outdated
      expect(build_role(convert_on: today)).to be_outdated
    end

    it 'is outdated if deleted_on is today or earlier unless deleted' do
      expect(build_role(delete_on: tomorrow)).not_to be_outdated
      expect(build_role(delete_on: yesterday)).to be_outdated
      expect(build_role(delete_on: today)).to be_outdated
      expect(build_role(delete_on: today, deleted_at: today)).not_to be_outdated
      expect(build_role(delete_on: today, deleted_at: yesterday)).not_to be_outdated
    end
  end

  context '#available_labels' do
    before { described_class.sweep_available_labels }
    subject { Group::BottomLayer::Leader.available_labels }

    it 'includes labels from database' do
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo',
                                                      group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'FOo',
                                                      group: groups(:bottom_layer_one))
      is_expected.to eq(['foo'])
    end

    it 'includes labels from all types' do
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo',
                                                      group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::Member.name.to_s, label: 'Bar',
                                                      group: groups(:bottom_layer_one))
      is_expected.to eq(%w(Bar foo))
    end
  end

  context '#start_on' do
    let(:tomorrow) { Time.zone.tomorrow }
    let(:today) { Time.zone.today }

    def build(attrs = {})
      Fabricate.build(:'Group::BottomLayer::Leader', attrs)
    end

    it 'returns today if created_at and convert_on is nil' do
      expect(build.start_on).to eq today
    end

    it 'returns created_at date if created_at is present and convert_on is nil' do
      expect(build(created_at: 1.day.ago).start_on).to eq Time.zone.yesterday
    end

    it 'returns convert_on if convert_on and created_at is set' do
      expect(build(created_at: 1.day.ago, convert_on: tomorrow).start_on).to eq tomorrow
    end
  end

  context '#end_on' do
    let(:tomorrow) { Time.zone.tomorrow }
    let(:today) { Time.zone.today }

    def build(attrs = {})
      Fabricate.build(:'Group::BottomLayer::Leader', attrs)
    end

    it 'returns nil if delete_on and deleted_at is nil' do
      expect(build.end_on).to be_nil
    end

    it 'returns delete_on if delete_on is present and deleted_at is nil' do
      expect(build(delete_on: tomorrow).end_on).to eq tomorrow
    end

    it 'returns deleted_at if deleted_at is present and delete_on is nil' do
      expect(build(deleted_at: 1.day.ago).end_on).to eq Time.zone.yesterday
    end

    it 'returns delete_on if delete_on and deleted_at is set' do
      expect(build(deleted_at: 1.day.ago, delete_on: tomorrow).end_on).to eq tomorrow
    end
  end

  context '#active_period' do
    let(:tomorrow) { Time.zone.tomorrow }
    let(:today) { Time.zone.today }

    def build(attrs = {})
      Fabricate.build(:'Group::BottomLayer::Leader', attrs)
    end

    it 'returns today..nil if created_at and convert_on is nil' do
      expect(build.active_period).to eq today..nil
    end

    it 'returns created_at..nil if created_at is present and convert_on is nil' do
      expect(build(created_at: 1.day.ago).active_period).to eq Time.zone.yesterday..nil
    end

    it 'returns convert_on..nil if convert_on and created_at is set' do
      expect(build(created_at: 1.day.ago, convert_on: tomorrow).active_period).to eq tomorrow..nil
    end

    it 'returns today..delete_on if delete_on and deleted_at is nil' do
      expect(build(delete_on: tomorrow).active_period).to eq today..tomorrow
    end

    it 'returns today..deleted_at if deleted_at is present and delete_on is nil' do
      expect(build(deleted_at: 1.day.ago).active_period).to eq today..Time.zone.yesterday
    end

    it 'returns today..delete_on if delete_on and deleted_at is set' do
      expect(build(deleted_at: 1.day.ago, delete_on: tomorrow).active_period).to eq today..tomorrow
    end
  end

  context '#create' do
    let(:person) { people(:top_leader) }

    it 'nullifies minimized_at of person' do
      person.update!(minimized_at: Time.zone.now)
      expect(person.minimized_at).to be_present

      Group::TopGroup::Member.create!(person: person, group: groups(:top_group))

      person.reload

      expect(person.minimized_at).to be_nil
    end
  end

  context '#destroy' do
    it 'deleted young roles from database' do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo',
                                                          group: groups(:bottom_layer_one))
      a.destroy
      expect(described_class.with_deleted.where(id: a.id)).not_to be_exists
    end

    it 'soft deletes young roles with always_soft_destroy: true' do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo',
                                                          group: groups(:bottom_layer_one))

      a.destroy(always_soft_destroy: true)
      expect(described_class.only_deleted.find(a.id)).to be_present
    end

    it 'flags old roles' do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo',
                                                          group: groups(:bottom_layer_one))
      a.created_at = Time.zone.now - Settings.role.minimum_days_to_archive.days - 1.day
      a.destroy
      expect(described_class.only_deleted.find(a.id)).to be_present
    end

    describe 'deleted_at' do
      let(:group) { groups(:bottom_layer_one) }
      let(:now) { Time.zone.now }
      before { freeze_time }

      def create_role(attrs = {})
        Fabricate(group.role_types.first.sti_name, attrs.merge(group: group))
      end

      it 'is set to now if delete_on is not set' do
        a = create_role
        expect { a.destroy }.to change { a.deleted_at }.from(nil).to(now)
      end

      it 'is set to now if delete_on is in the future' do
        a = create_role(created_at: 2.days.ago, delete_on: Date.tomorrow)
        expect { a.destroy }.to change { a.deleted_at }.from(nil).to(now)
      end

      it 'is set to delete_on at midnight if delete_on is in the past' do
        a = create_role(created_at: 2.days.ago, delete_on: Date.yesterday)
        expect { a.destroy }.to change { a.deleted_at }.from(nil).to(Date.yesterday.midnight)
      end
    end

    it 'flags old roles' do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo',
                                                          group: groups(:bottom_layer_one))
      a.created_at = Time.zone.now - Settings.role.minimum_days_to_archive.days - 1.day
      a.destroy
      expect(described_class.only_deleted.find(a.id)).to be_present
    end
  end

  context '#destroy!' do
    it 'soft deletes young roles with always_soft_destroy: true' do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo',
                                                          group: groups(:bottom_layer_one))

      a.destroy!(always_soft_destroy: true)
      expect(described_class.only_deleted.find(a.id)).to be_present
    end
  end

  context '#in_primary_group?' do
    let(:role) { roles(:bottom_member) }

    it 'is true if role is in primary group' do
      role.person.update!(primary_group: role.group)
      expect(role.in_primary_group?).to eq true
    end

    it 'is false if role is not in primary group' do
      role.person.update!(primary_group: groups(:top_group))
      expect(role.in_primary_group?).to eq false
    end
  end

  context '#label_long adds group to role', focus: true do
    subject { role.label_long }

    context 'group with long key' do
      let(:role) { Group::BottomLayer::Leader }
      it { is_expected.to eq 'Leader Bottom Layer Long' }
    end

    context 'group without long key' do
      let(:role) { Group::BottomGroup::Leader }
      it { is_expected.to eq 'Leader Bottom Group' }
    end
  end

  context '#terminated' do
    it 'can not be assigned directly' do
      role = Role.new
      expect { role.terminated = true }.to raise_error(/do not set terminated directly/)
    end

    it 'can not be updated directly' do
      role = roles(:bottom_member)
      expect { role.update!(terminated: true) }.to raise_error(/do not set terminated directly/)
    end
  end

  context '#terminatable?' do
    let(:role_class) { Class.new(Role) }

    context 'when ::terminatable=false' do
      it 'is false by default' do
        assert !role_class.terminatable
        expect(role_class.new.terminatable?).to eq false
      end
    end

    context 'when ::terminatable=true' do
      before { role_class.terminatable = true }

      it 'is true' do
        expect(role_class.new.terminatable?).to eq true
      end

      it 'is false if role is terminated' do
        role = role_class.new.tap { |r| r.write_attribute(:terminated, true) }
        expect(role.terminatable?).to eq false
      end

      it 'is false if role is archived' do
        role = role_class.new(archived_at: 1.day.from_now)
        expect(role.terminatable?).to eq false
      end

      it 'is false if role is deleted' do
        role = role_class.new(deleted_at: 1.day.from_now)
        expect(role.terminatable?).to eq false
      end
    end
  end

  context '#terminated_on' do
    def role(**attrs)
      terminated = attrs.delete(:terminated) || false
      Role.new(attrs.reverse_merge(delete_on: nil, deleted_at: nil)).tap do |r|
        r.write_attribute(:terminated, terminated)
      end
    end

    it 'returns nil if role is not terminated' do
      expect(role(delete_on: 1.day.from_now).terminated_on).to be_nil
      expect(role(deleted_at: 1.day.from_now).terminated_on).to be_nil
    end

    it 'returns delete_on if role is terminated' do
      date = 1.day.from_now.to_date
      expect(role(terminated: true, delete_on: date).terminated_on).to eq date
    end

    it 'returns deleted_at if role is terminated' do
      date = 1.day.from_now.to_date
      expect(role(terminated: true, deleted_at: date).terminated_on).to eq date
    end

    it 'delete_on takes precedence over deleted_at' do
      delete_on = 1.day.from_now.to_date
      deleted_at = 2.days.from_now.to_date
      expect(role(terminated: true, delete_on: delete_on,
                  deleted_at: deleted_at).terminated_on).to eq delete_on
    end
  end

  context 'paper trails', versioning: true do
    let(:person) { people(:top_leader) }

    it 'sets main on create' do
      expect do
        role = person.roles.build
        role.group = groups(:top_group)
        role.type = Group::TopGroup::Leader.sti_name
        role.save!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq('create')
      expect(version.main).to eq(person)
    end

    it 'sets main on update' do
      role = person.roles.first
      expect do
        role.update!(label: 'Foo')
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq('update')
      expect(version.main).to eq(person)
    end

    it 'sets main on destroy' do
      role = person.roles.first
      expect do
        role.really_destroy!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq('destroy')
      expect(version.main).to eq(person)
    end
  end

  context 'archived:' do
    around do |spec|
      previous = Settings.role.minimum_days_to_archive
      Settings.role.minimum_days_to_archive = 0

      spec.run

      Settings.role.minimum_days_to_archive = previous || 7
    end

    subject(:archived_role) do
      roles(:bottom_member).tap { |r| r.update(archived_at: 1.day.ago) }
    end

    context 'archived? is' do
      subject { roles(:bottom_member) }

      it 'false without a date' do
        expect(subject.archived_at).to be_falsey

        is_expected.not_to be_archived
      end

      it 'true with an archived_at date' do
        expect(archived_role.archived_at).to be_truthy

        expect(archived_role).to be_archived
      end

      it 'making the role read-only' do
        expect(archived_role).to be_archived

        expect do
          archived_role.update!(label: 'Follower of Blørbaël')
        end.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end

    context 'soft-deletion' do
      it 'is supported' do
        expect(archived_role.class.ancestors).to include(Paranoia)

        expect do
          archived_role.destroy!
        end.to change { described_class.without_deleted.count }.by(-1)

        expect(archived_role.reload.deleted_at).to_not be_nil
      end
    end
  end

  context 'nextcloud groups' do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:bottom_layer_one) }
    let(:nextcloud_group_mapping) { false }

    subject do
      r = described_class.new # Group::BottomLayer::Leader.new
      r.class.nextcloud_group = nextcloud_group_mapping
      r.type = 'Group::BottomLayer::Leader'
      r.person = person
      r.group = group
      r
    end

    after do
      subject.class.nextcloud_group = false
    end

    it 'have assumptions' do
      expect(Settings.groups.nextcloud.enabled).to be true # in the test-env
    end

    describe 'role without mapping' do
      let(:nextcloud_group_mapping) { false }

      it 'has a value of false' do
        expect(subject.class.nextcloud_group).to be false
      end

      it 'does not return any nextcloud groups' do
        expect(subject.nextcloud_group).to be_nil
      end
    end

    describe 'role with constant mapping' do
      let(:nextcloud_group_mapping) { 'Admins' }

      it 'has a String-value' do
        expect(subject.class.nextcloud_group).to eq 'Admins'
      end

      it 'does not return any nextcloud groups' do
        expect(subject.nextcloud_group.to_h).to eq(
          'gid' => 'hitobito-Admins',
          'displayName' => 'Admins'
        )
      end
    end

    describe 'role with dynamic mapping' do
      let(:nextcloud_group_mapping) { true }
      let(:group) do
        Group::GlobalGroup.new(id: 1024, name: 'Test', parent: groups(:top_layer))
      end

      it 'has a value of false' do
        expect(subject.class.nextcloud_group).to be true
      end

      it 'does not return any nextcloud groups' do
        expect(subject.nextcloud_group.to_h).to eq(
          'gid' => '1024',
          'displayName' => 'Test'
        )
      end
    end

    describe 'role with a method mapping' do
      let(:nextcloud_group_mapping) { :my_nextcloud_group }

      before do
        subject.define_singleton_method :my_nextcloud_group do
          { 'gid' => '1234', 'displayName' => 'TestGruppe' }
        end
      end

      it 'has a Symbol as value' do
        expect(subject.class.nextcloud_group).to be_a Symbol
      end

      it 'responds to the method' do
        is_expected.to respond_to :my_nextcloud_group
      end

      it 'delegates to the other group' do
        expect(subject.nextcloud_group.to_h).to eq(
          'gid' => '1234',
          'displayName' => 'TestGruppe'
        )
      end
    end

    describe 'role with a proc mapping' do
      let(:nextcloud_group_mapping) do
        proc do |role|
          {
            'gid' => role.type,
            'displayName' => role.class.name.humanize
          }
        end
      end

      it 'has a Symbol as value' do
        expect(subject.class.nextcloud_group).to be_a Proc
      end

      it 'delegates to the Proc' do
        expect(subject.nextcloud_group.to_h).to eq(
          'gid' => 'Group::BottomLayer::Leader',
          'displayName' => 'Role'
        )
      end
    end
  end

end
