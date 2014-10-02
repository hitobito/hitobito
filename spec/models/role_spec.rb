# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  person_id  :integer          not null
#  group_id   :integer          not null
#  type       :string(255)      not null
#  label      :string(255)
#  created_at :datetime
#  updated_at :datetime
#  deleted_at :datetime
#

require 'spec_helper'

describe Role do

  context 'class' do
    subject { Role }

    its(:all_types) { should have(13).items }

    its(:visible_types) { should have(11).items }

    its(:visible_types) { should_not include(Group::BottomGroup::Member) }

    it 'should have two types with permission :layer_and_below_full' do
      Role.types_with_permission(:layer_and_below_full).to_set.should == [Group::TopGroup::Leader, Group::BottomLayer::Leader].to_set
    end

    it 'should have no types with permission :not_existing' do
      Role.types_with_permission(:not_existing).should be_empty
    end
  end

  context 'regular' do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:bottom_layer_one) }
    subject do
      r = Role.new # Group::BottomLayer::Leader.new
      r.type = 'Group::BottomLayer::Leader'
      r.person = person
      r.group = group
      r
    end

    context 'type' do
      it 'is invalid without type' do
        subject.type = nil
        should have(1).errors_on(:type)
      end

      it 'is invalid with non-existing type' do
        subject.type = 'Foo'
        should have(1).errors_on(:type)
      end

      it 'is invalid with type from other group' do
        subject.type = 'Group::TopGroup::Leader'
        should have(1).errors_on(:type)
      end

      it 'is valid with allowed type' do
        subject.type = 'Group::BottomLayer::Leader'
        should be_valid
      end
    end

    context 'primary group' do
      # before { subject.type = 'Group::BottomLayer::Leader' }

      it 'is set for first role' do
        subject.save.should be_true
        person.primary_group_id.should == group.id
      end

      it 'is not set on subsequent roles' do
        Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
        subject.save
        person.primary_group_id.should_not == group.id
      end

      it 'is reset if role is destroyed' do
        subject.save
        subject.destroy.should be_true
        person.primary_group_id.should be_nil
      end

      it 'is not reset if role is destroyed and other roles in the same group exist' do
        Fabricate(Group::BottomLayer::Member.name.to_s, person: person, group: group)
        subject.save
        subject.destroy.should be_true
        person.primary_group_id.should == group.id
      end

      it 'is not reset if role is destroyed and primary group is another group' do
        subject.save
        person.update_column :primary_group_id, 42
        subject.destroy.should be_true
        person.primary_group_id.should == 42
      end
    end

    context 'contact data callback' do

      it 'sets contact data flag on person' do
        subject.type = 'Group::BottomLayer::Leader'
        subject.save!
        person.should be_contact_data_visible
      end

      it 'sets contact data flag on person with flag' do
        person.update_attribute :contact_data_visible, true
        subject.type = 'Group::BottomLayer::Leader'
        subject.save!
        person.should be_contact_data_visible
      end

      it 'removes contact data flag on person ' do
        person.update_attribute :contact_data_visible, true
        subject.type = 'Group::BottomLayer::Leader'
        subject.save!

        role = Role.find(subject.id)  # reload from db to get the correct class
        role.destroy

        person.reload.should_not be_contact_data_visible
      end

      it 'does not remove contact data flag on person when other roles exist' do
        Fabricate(Group::TopGroup::Member.name.to_s, group: groups(:top_group), person: person)
        subject.type = 'Group::BottomLayer::Leader'
        subject.save!

        role = Role.find(subject.id)  # reload from db to get the correct class
        role.destroy

        person.reload.should be_contact_data_visible
      end
    end
  end

  context '.normalize_label' do
    it 'reuses existing label' do
      a1 = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo', group: groups(:bottom_layer_one))
      a2 = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'fOO', group: groups(:bottom_layer_one))
      a2.label.should == 'foo'
    end
  end

  context '#available_labels' do
    before { Role.sweep_available_labels }
    subject { Group::BottomLayer::Leader.available_labels }

    it 'includes labels from database' do
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo', group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'FOo', group: groups(:bottom_layer_one))
      should == ['foo']
    end

    it 'includes labels from all types' do
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo', group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::Member.name.to_s, label: 'Bar', group: groups(:bottom_layer_one))
      should == %w(Bar foo)
    end
  end

  context '#destroy' do
    it 'deleted young roles from database' do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo', group: groups(:bottom_layer_one))
      a.destroy
      Role.with_deleted.where(id: a.id).should_not be_exists
    end

    it 'flags old roles' do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo', group: groups(:bottom_layer_one))
      a.created_at = Time.zone.now - Settings.role.minimum_days_to_archive.days - 1.day
      a.destroy
      Role.only_deleted.find(a.id).should be_present
    end
  end

  context '#label_long adds group to role', focus: true do
    subject { role.label_long }

    context 'group with long key' do
      let(:role) { Group::BottomLayer::Leader }
      it { should eq 'Leader Bottom Layer Long' }
    end

    context 'group without long key' do
      let(:role) { Group::BottomGroup::Leader }
      it { should eq 'Leader Bottom Group' }
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
      version.event.should == 'create'
      version.main.should == person
    end

    it 'sets main on update' do
      role = person.roles.first
      expect do
        role.update_attributes!(label: 'Foo')
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      version.event.should == 'update'
      version.main.should == person
    end

    it 'sets main on destroy' do
      role = person.roles.first
      expect do
        role.really_destroy!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      version.event.should == 'destroy'
      version.main.should == person
    end
  end
end
