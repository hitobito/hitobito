# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: groups
#
#  id                          :integer          not null, primary key
#  parent_id                   :integer
#  lft                         :integer
#  rgt                         :integer
#  name                        :string           not null
#  short_name                  :string(31)
#  type                        :string           not null
#  email                       :string
#  address                     :string(1024)
#  zip_code                    :integer
#  town                        :string
#  country                     :string
#  contact_id                  :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  deleted_at                  :datetime
#  layer_group_id              :integer
#  creator_id                  :integer
#  updater_id                  :integer
#  deleter_id                  :integer
#  require_person_add_requests :boolean          default(FALSE), not null

require 'spec_helper'

describe Group do

  it 'should load fixtures' do
    expect(groups(:top_layer)).to be_present
  end

  it 'is a valid nested set' do
    expect(Group).to be_valid
  end

  context 'alphabetic order' do
    context 'on insert' do
      it 'at the beginning' do
        updated = 2.days.ago.to_date
        Group.update_all(updated_at: updated)
        expect(groups(:top_layer).reload.updated_at.to_date).to eq(updated)
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: 'AAA', parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          'AAA', 'Bottom One', 'Bottom Two', 'TopGroup', 'Toppers']
        # :updated_at should not change, tests patch from config/awesome_nested_set_patch.rb
        expect(groups(:top_layer).reload.updated_at.to_date).to eq(updated)
        expect(groups(:bottom_layer_one).reload.updated_at.to_date).to eq(updated)
        expect(groups(:bottom_layer_two).reload.updated_at.to_date).to eq(updated)
      end

      it 'at the beginning with same name' do
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: 'Bottom One', parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          'Bottom One', 'Bottom One', 'Bottom Two', 'TopGroup', 'Toppers']
      end

      it 'in the middle' do
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: 'Frosch', parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'Bottom Two', 'Frosch', 'TopGroup', 'Toppers']
      end

      it 'in the middle with same name' do
        parent = groups(:top_layer)
        group = Group::BottomLayer.new(name: 'Bottom Two', parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'Bottom Two', 'Bottom Two', 'TopGroup', 'Toppers']
      end

      it 'at the end' do
        parent = groups(:top_layer)
        group = Group::TopGroup.new(name: 'ZZ Top', parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'Bottom Two', 'TopGroup', 'Toppers', 'ZZ Top']
      end

      it 'at the end with same name' do
        parent = groups(:top_layer)
        group = Group::TopGroup.new(name: 'Toppers', parent_id: parent.id)
        group.save!
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'Bottom Two', 'TopGroup', 'Toppers', 'Toppers']
      end

      context 'with short_name' do
        it 'in the middle' do
          parent = groups(:top_layer)
          group = Group::TopGroup.new(name: 'Bottom A', short_name: 'Bottom X', parent_id: parent.id)
          group.save!
          expect = expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
           'Bottom One', 'Bottom Two','Bottom A', 'TopGroup', 'Toppers']
        end
      end

      context 'with lowercase' do
        it 'in the middle' do
          parent = groups(:top_layer)
          group = Group::TopGroup.new(name: 'bottom x', parent_id: parent.id)
          group.save!
          expect = expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
           'Bottom One', 'Bottom Two', 'bottom x', 'TopGroup', 'Toppers']
        end
      end
    end

    context 'on update' do
      it 'at the beginning' do
        groups(:bottom_layer_two).update!(name: 'AAA')
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          'AAA', 'Bottom One', 'TopGroup', 'Toppers']
      end

      it 'at the beginning with same name' do
        groups(:bottom_layer_two).update!(name: 'Bottom One')
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
          'Bottom One', 'Bottom One', 'TopGroup', 'Toppers']
      end

      it 'in the middle keeping position right' do
        groups(:bottom_layer_two).update!(name: 'Frosch')
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'Frosch', 'TopGroup', 'Toppers']
      end

      it 'in the middle keeping position left' do
        groups(:bottom_layer_two).update!(name: 'Bottom P')
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'Bottom P', 'TopGroup', 'Toppers']
      end

      it 'in the middle moving right' do
        groups(:bottom_layer_two).update!(name: 'TopGzzz')
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'TopGroup', 'TopGzzz', 'Toppers']
      end

      it 'in the middle moving left' do
        groups(:top_group).update!(name: 'Bottom P')
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'Bottom P', 'Bottom Two', 'Toppers']
      end

      it 'in the middle with same name' do
        groups(:bottom_layer_two).update!(name: 'TopGroup')
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'TopGroup', 'TopGroup', 'Toppers']
      end

      it 'at the end' do
        groups(:bottom_layer_two).update!(name: 'ZZ Top')
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'TopGroup', 'Toppers', 'ZZ Top']
      end

      it 'at the end with same name' do
        groups(:bottom_layer_two).update!(name: 'Toppers')
        expect(groups(:top_layer).children.order(:lft).collect(&:name)).to eq [
         'Bottom One', 'TopGroup', 'Toppers', 'Toppers']
      end

      context 'with short_name' do
        it 'at the end' do
          groups(:bottom_layer_two).update!(short_name: 'XXX')
          expect(groups(:top_layer).children.order(:lft).collect(&:display_name)).to eq [
           'Bottom One', 'TopGroup', 'Toppers', "XXX"]
        end
      end

      context 'with lowercase' do
        it 'in the middle' do
          groups(:bottom_layer_two).update!(name: 'topGroupX')
          expect(groups(:top_layer).children.order(:lft).collect(&:display_name)).to eq [
           'Bottom One', 'TopGroup', 'topGroupX', 'Toppers']
        end
      end

    end
  end

  context '#hierachy' do
    it 'is itself for root group' do
      expect(groups(:top_layer).hierarchy).to eq([groups(:top_layer)])
    end

    it 'contains all ancestors' do
      expect(groups(:bottom_group_one_one).hierarchy).to eq([groups(:top_layer), groups(:bottom_layer_one), groups(:bottom_group_one_one)])
    end
  end

  context '#layer_hierarchy' do
    it 'is itself for top layer' do
      expect(groups(:top_layer).layer_hierarchy).to eq([groups(:top_layer)])
    end

    it 'is next upper layer for top layer group' do
      expect(groups(:top_group).layer_hierarchy).to eq([groups(:top_layer)])
    end

    it 'is all upper layers for regular layer' do
      expect(groups(:bottom_layer_one).layer_hierarchy).to eq([groups(:top_layer), groups(:bottom_layer_one)])
    end
  end

  context '#layer_group' do
    it 'is itself for layer' do
      expect(groups(:top_layer).layer_group).to eq(groups(:top_layer))
    end

    it 'is next upper layer for regular group' do
      expect(groups(:bottom_group_one_one).layer_group).to eq(groups(:bottom_layer_one))
    end
  end

  context '#upper_layer_hierarchy' do
    context 'for existing group' do
      it 'contains only upper for layer' do
        expect(groups(:bottom_layer_one).upper_layer_hierarchy).to eq([groups(:top_layer)])
      end

      it 'contains only upper for group' do
        expect(groups(:bottom_group_one_one).upper_layer_hierarchy).to eq([groups(:top_layer)])
      end

      it 'is empty for top layer' do
        expect(groups(:top_group).upper_layer_hierarchy).to be_empty
      end
    end

    context 'for new group' do
      it 'contains only upper for layer' do
        group = Group::BottomLayer.new
        group.parent = groups(:top_layer)
        expect(group.upper_layer_hierarchy).to eq([groups(:top_layer)])
      end

      it 'contains only upper for group' do
        group = Group::BottomGroup.new
        group.parent = groups(:bottom_layer_one)
        expect(group.upper_layer_hierarchy).to eq([groups(:top_layer)])
      end

      it 'is empty for top layer' do
        group = Group::TopGroup.new
        group.parent = groups(:top_layer)
        expect(group.upper_layer_hierarchy).to be_empty
      end
    end
  end

  context '#sister_groups_with_descendants' do
    subject { group.sister_groups_with_descendants.to_a }

    context 'for root' do
      let(:group) { groups(:top_layer) }

      it 'contains all groups' do
        is_expected.to match_array(Group.all)
      end
    end

    context 'for group without children or sisters' do
      let(:group) { groups(:top_group) }

      it 'only contains self' do
        is_expected.to eq([group])
      end
    end

    context 'for layer' do
      let(:group) { groups(:bottom_layer_one) }

      it 'contains other layers and their descendants' do
        is_expected.to match_array([group.self_and_descendants, groups(:bottom_layer_two).self_and_descendants].flatten)
      end
    end

    context 'for group' do
      let(:group) { groups(:bottom_group_one_one) }

      it 'contains other groups and their descendants' do
        is_expected.to match_array([group, groups(:bottom_group_one_one_one), groups(:bottom_group_one_two)])
      end
    end
  end

  context '.all_types' do
    it 'lists all types' do
      expect(Group.all_types.count).to eq(5)
      [Group::TopLayer, Group::TopGroup, Group::BottomLayer, Group::BottomGroup, Group::GlobalGroup].each do |t|
        expect(Group.all_types).to include(t)
      end
    end
  end

  context '.order_by_type' do
    it 'has correct ordering without group' do
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

    it 'has correct ordering with parent group' do
      parent = groups(:top_layer)
      expect(parent.children.order_by_type(parent)).to eq(
          [groups(:top_group),
           groups(:bottom_layer_one),
           groups(:bottom_layer_two),
           groups(:toppers)]
      )
    end

    it 'works without possible groups' do
      parent = groups(:bottom_group_one_two)
      expect(parent.children.order_by_type(parent)).to be_empty
    end
  end


  context '#set_layer_group_id' do
    it 'sets layer_group_id on group' do
      top_layer = groups(:top_layer)
      group = Group::TopGroup.new(name: 'foobar')
      group.parent_id = top_layer.id
      group.save!
      expect(group.layer_group_id).to eq top_layer.id
    end

    it 'sets layer_group_id on group with default children' do
      group = Group::TopLayer.new(name: 'foobar')
      group.save!
      expect(group.layer_group_id).to eq group.id
      expect(group.children).to be_present
      expect(group.children.first.layer_group_id).to eq group.id
    end

    it 'sets the layer group on all descendants if parent changes' do
      group = groups(:bottom_group_one_one)
      group.update!(parent_id: groups(:bottom_layer_two).id)
      expect(group.reload.layer_group_id).to eq(groups(:bottom_layer_two).id)
      expect(groups(:bottom_group_one_one_one).layer_group_id).to eq(groups(:bottom_layer_two).id)
    end
  end

  context '#destroy' do
    let(:top_leader) { roles(:top_leader) }
    let(:top_layer) { groups(:top_layer) }
    let(:bottom_layer) { groups(:bottom_layer_one) }
    let(:bottom_group) { groups(:bottom_group_one_two) }

    it 'destroys self' do
      expect { bottom_group.destroy }.to change { Group.without_deleted.count }.by(-1)
      expect(Group.only_deleted.collect(&:id)).to  match_array([bottom_group.id])
      expect(Group).to be_valid
    end

    it 'hard destroys self' do
      expect { bottom_group.really_destroy! }.to change { Group.with_deleted.count }.by(-1)
      expect(Group).to be_valid
    end

    it 'protects group with children' do
      expect { bottom_layer.destroy }.not_to change { Group.without_deleted.count }
    end

    it 'does not destroy anything for root group' do
      expect { top_layer.destroy }.not_to change { Group.count }
    end

    context 'role assignments'  do
      it 'terminates own roles' do
        role = Fabricate(Group::BottomGroup::Member.name.to_s, group: bottom_group)
        deleted_ids = bottom_group.roles.collect(&:id)
        # role is deleted permanantly as it is less than Settings.role.minimum_days_to_archive old
        expect { bottom_group.destroy }.to change { Role.with_deleted.count }.by(-1)
      end
    end

    context 'events' do
      let(:group) { groups(:bottom_group_one_two) }

      it 'does not destroy exclusive events on soft destroy' do
        Fabricate(:event, groups: [group])
        expect { group.destroy }.not_to change { Event.count }
      end

      it 'destroys exclusive events on hard destroy' do
        Fabricate(:event, groups: [group])
        expect { group.really_destroy! }.to change { Event.count }.by(-1)
      end

      it 'does not destroy events belonging to other groups as well' do
        Fabricate(:event, groups: [group, groups(:bottom_group_one_one)])
        expect { group.really_destroy! }.not_to change { Event.count }
      end

      it 'destroys event when removed from association' do
        expect { top_layer.events = [events(:top_event)] }.to change { Event.count }.by(-1)
      end
    end
  end

  context 'contacts' do
    let(:contactable) { { address: 'foobar', zip_code: 3600, town: 'thun', country: 'ch' } }
    let(:group) { groups(:top_group) }

    subject { group }
    before { group.update!(contactable) }

    context 'no contactable but contact info'  do
      its(:contact)   { should be_blank }
      its(:address)   { should eq 'foobar' }
      its(:town)      { should eq 'thun' }
      its(:zip_code)  { should eq 3600 }
      its(:country)   { should eq 'CH' }
    end

    context 'discards contact info when contactable is set' do
      let(:contact) { Fabricate(:person, other_contactable) }
      let(:other_contactable) { { address: 'barfoo', zip_code: nil } }

      before { group.update_attribute(:contact, contact) }

      its(:address)   { should eq 'barfoo' }
      its(:address?)   { should be_truthy }
      its(:zip_code?)   { should be_falsey }
    end

  end

  context 'invoice_config' do
    let (:parent) { groups(:top_layer) }

    it 'is created for layer group' do
      group = Fabricate(Group::BottomLayer.sti_name, name: 'g', parent: parent)
      expect(group.invoice_config).to be_present
    end

    it 'is not created for non layer group' do
      group = Fabricate(Group::TopGroup.sti_name, name: 'g', parent: parent)
      expect(group.invoice_config).not_to be_present
    end

    it 'is destroyed group when group gets destroyed' do
      group = Fabricate(Group::BottomLayer.sti_name, name: 'g', parent: parent)
      expect { group.destroy }.to change { InvoiceConfig.count }.by(-1)
    end
  end

  describe 'e-mail validation' do

    let(:group) { groups(:top_layer) }

    before { allow(Truemail).to receive(:valid?).and_call_original }

    it 'does not allow invalid e-mail address' do
      group.email = 'blabliblu-ke-email'

      expect(group).not_to be_valid
      expect(group.errors.messages[:email].first).to eq('ist nicht gültig')
    end

    it 'allows blank e-mail address' do
      group.email = '   '

      expect(group).to be_valid
      expect(group.email).to be_nil
    end

    it 'does not allow e-mail address with non-existing domain' do
      group.email = 'group42@gitsäuäniä.it'

      expect(group).not_to be_valid
      expect(group.errors.messages[:email].first).to eq('ist nicht gültig')
    end

    it 'does not allow e-mail address with domain without mx record' do
      group.email = 'dudes@bluewin.com'

      expect(group).not_to be_valid
      expect(group.errors.messages[:email].first).to eq('ist nicht gültig')
    end

    it 'does allow valid e-mail address' do
      group.email = 'group42@puzzle.ch'

      expect(group).to be_valid
    end
  end
end
