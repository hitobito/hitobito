# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PersonAbility do

  subject { ability }
  let(:ability) { Ability.new(role.person.reload) }

  describe :layer_and_below_full do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'may modify any public role in lower layers' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
      should be_able_to(:update, other)
    end

    it 'may not update root email if in same group' do
      root = people(:root)
      Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group), person: root)
      should be_able_to(:update, root.reload)
      should_not be_able_to(:update_email, root)
    end

    it 'may modify its role' do
      should be_able_to(:update, role)
    end

    it 'may modify its password' do
      should be_able_to(:update_email, role.person)
    end

    it 'may not destroy its role' do
      should_not be_able_to(:destroy, role)
    end

    it 'may modify externals in the same layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_layer))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
      should be_able_to(:update, other)
    end

    it 'may not view any non-visible in lower layers' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      should_not be_able_to(:show_full, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not view any externals in lower layers' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:show_full, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may index groups in lower layer' do
      should be_able_to(:index_people, groups(:bottom_layer_one))
      should be_able_to(:index_full_people, groups(:bottom_layer_one))
      should_not be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may index groups in same layer' do
      should be_able_to(:index_people, groups(:top_layer))
      should be_able_to(:index_full_people, groups(:top_layer))
      should be_able_to(:index_local_people, groups(:top_layer))
    end
  end


  describe 'layer_and_below_full in bottom layer' do
    let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }

    it 'may create other users' do
      should be_able_to(:create, Person)
    end

    it 'may modify its role' do
      should be_able_to(:update, role)
    end

    it 'may not destroy its role' do
      should_not be_able_to(:destroy, role)
    end

    it 'may modify any public role in same layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym,
                        group: groups(:bottom_layer_one),
                        person: Fabricate(:person, password: 'foobar', password_confirmation: 'foobar'))
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
      should be_able_to(:update, other)
      should be_able_to(:create, other)
      should be_able_to(:destroy, other)
    end

    it 'may not view any public role in upper layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:show_full, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not update email for person with role in upper layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should_not be_able_to(:update_email, other.person)
    end

    it 'may not view any public role in other layer' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      should_not be_able_to(:show_full, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not update email for person with role in other layer' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should_not be_able_to(:update_email, other.person)
    end

    it 'may update email for person with role in other layer if layer_and_below_full there' do
      Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two), person: role.person)
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may update email for person with role in other group if group_full there' do
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one), person: role.person)
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_two_one))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may update email for person with uncapable role in upper layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may update email for person with uncapable role in other layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may update email for uncapable person with uncapable role in other layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may not update email for uncapable person with role in other layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should_not be_able_to(:update_email, other.person)
    end

    it 'may modify externals in his layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update, other)
      should be_able_to(:create, other)
      should be_able_to(:destroy, other)
    end

    it 'may modify children in his layer' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
      should be_able_to(:update, other)
      should be_able_to(:create, other)
      should be_able_to(:destroy, other)
    end

    it 'may not view any externals in upper layers' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:show_full, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may index groups in upper layer' do
      should be_able_to(:index_people, groups(:top_layer))
      should_not be_able_to(:index_full_people, groups(:top_layer))
      should_not be_able_to(:index_local_people, groups(:top_layer))
    end

    it 'may index groups in same layer' do
      should be_able_to(:index_people, groups(:bottom_layer_one))
      should be_able_to(:index_full_people, groups(:bottom_layer_one))
      should be_able_to(:index_local_people, groups(:bottom_layer_one))
    end
  end


  describe :layer_and_below_read do
    # member with additional group_full role
    let(:role)       { Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)) }

    it 'may view details of himself' do
      should be_able_to(:show_full, role.person.reload)
    end

    it 'may modify himself' do
      should be_able_to(:update, role.person.reload)
    end

    it 'may modify its read role' do
      should be_able_to(:update, role)
    end

    it 'may not destroy its role' do
      should_not be_able_to(:destroy, role)
    end

    it 'may create other users as group admin' do
      should be_able_to(:create, Person)
    end

    it 'may view any public role in same layer' do
      other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers))
      should be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify any role in same layer' do
      other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers))
      should_not be_able_to(:update, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may view any externals in same layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:toppers))
      should be_able_to(:show_full, other.person.reload)
    end

    it 'may modify any role in same group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update, other)
    end

    it 'may view any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      should be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:update, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not view any externals in groups below' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:show, other.person.reload)
    end

    it 'may index groups in lower layer' do
      should be_able_to(:index_people, groups(:bottom_layer_one))
      should be_able_to(:index_full_people, groups(:bottom_layer_one))
      should_not be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may index groups in same layer' do
      should be_able_to(:index_people, groups(:toppers))
      should be_able_to(:index_full_people, groups(:toppers))
      should be_able_to(:index_local_people, groups(:toppers))
    end
  end


  describe :layer_full do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

    it 'may not modify any public role in lower layers' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:update, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not update root email if in same group' do
      root = people(:root)
      Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group), person: root)
      should be_able_to(:update, root.reload)
      should_not be_able_to(:update_email, root)
    end

    it 'may modify its role' do
      should be_able_to(:update, role)
    end

    it 'may modify its password' do
      should be_able_to(:update_email, role.person)
    end

    it 'may not destroy its role' do
      should_not be_able_to(:destroy, role)
    end

    it 'may modify externals in the same layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_layer))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
      should be_able_to(:update, other)
    end

    it 'may not view any non-visible in lower layers' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      should_not be_able_to(:show, other.person.reload)
      should_not be_able_to(:show_full, other.person)
      should_not be_able_to(:update, other)
    end

    it 'may not view any non-contact data in lower layers' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:show, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not view any externals in lower layers' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:show, other.person.reload)
      should_not be_able_to(:show_full, other.person)
      should_not be_able_to(:update, other)
    end

    it 'may not index groups in lower layer' do
      should_not be_able_to(:index_people, groups(:bottom_layer_one))
      should_not be_able_to(:index_full_people, groups(:bottom_layer_one))
      should_not be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may index groups in same layer' do
      should be_able_to(:index_people, groups(:top_layer))
      should be_able_to(:index_full_people, groups(:top_layer))
      should be_able_to(:index_local_people, groups(:top_layer))
    end
  end


  describe 'layer_full in bottom layer' do
    let(:role) { Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_one)) }

    it 'may create other users' do
      should be_able_to(:create, Person)
    end

    it 'may modify its role' do
      should be_able_to(:update, role)
    end

    it 'may not destroy its role' do
      should_not be_able_to(:destroy, role)
    end

    it 'may modify any public role in same layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym,
                        group: groups(:bottom_layer_one),
                        person: Fabricate(:person, password: 'foobar', password_confirmation: 'foobar'))
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
      should be_able_to(:update, other)
      should be_able_to(:create, other)
      should be_able_to(:destroy, other)
    end

    it 'may not view any public role in upper layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:show_full, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not update email for person with role in upper layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should_not be_able_to(:update_email, other.person)
    end

    it 'may not view any public role in other layer' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      should_not be_able_to(:show_full, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not view any private role in other layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_two))
      should_not be_able_to(:show, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not update email for person with role in other layer' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should_not be_able_to(:update_email, other.person)
    end

    it 'may update email for person with role in other layer if layer_full there' do
      Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_two), person: role.person)
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may update email for person with role in other group if group_full there' do
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one), person: role.person)
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_two_one))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may update email for person with uncapable role in upper layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may update email for person with uncapable role in other layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may update email for uncapable person with uncapable role in other layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may not update email for uncapable person with role in other layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      should be_able_to(:update, other.person.reload)
      should_not be_able_to(:update_email, other.person)
    end

    it 'may modify externals in his layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update, other)
      should be_able_to(:create, other)
      should be_able_to(:destroy, other)
    end

    it 'may modify children in his layer' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
      should be_able_to(:update, other)
      should be_able_to(:create, other)
      should be_able_to(:destroy, other)
    end

    it 'may not view any externals in upper layers' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:show_full, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may index groups in upper layer' do
      should_not be_able_to(:index_people, groups(:top_layer))
      should_not be_able_to(:index_full_people, groups(:top_layer))
      should_not be_able_to(:index_local_people, groups(:top_layer))
    end

    it 'may index groups in same layer' do
      should be_able_to(:index_people, groups(:bottom_layer_one))
      should be_able_to(:index_full_people, groups(:bottom_layer_one))
      should be_able_to(:index_local_people, groups(:bottom_layer_one))
    end
  end


  describe :layer_read do
    let(:role) { Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: groups(:top_group)) }

    it 'may view details of himself' do
      should be_able_to(:show_full, role.person.reload)
    end

    it 'may modify himself' do
      should be_able_to(:update, role.person.reload)
    end

    it 'may modify its read role' do
      should_not be_able_to(:update, role)
    end

    it 'may not destroy its role' do
      should_not be_able_to(:destroy, role)
    end

    it 'may create other users as group admin' do
      should_not be_able_to(:create, Person)
    end

    it 'may view any public role in same layer' do
      other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers))
      should be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify any role in same layer' do
      other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers))
      should_not be_able_to(:update, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may view any externals in same layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:toppers))
      should be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify any role in same group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:update, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not view any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:show, other.person.reload)
    end

    it 'may not modify any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:update, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not view any externals in groups below' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:show, other.person.reload)
    end

    it 'may index groups in lower layer' do
      should_not be_able_to(:index_people, groups(:bottom_layer_one))
      should_not be_able_to(:index_full_people, groups(:bottom_layer_one))
      should_not be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may index people same layer' do
      should be_able_to(:index_people, groups(:top_layer))
      should be_able_to(:index_full_people, groups(:top_layer))
      should be_able_to(:index_local_people, groups(:top_layer))
    end

    it 'may index people in groups in same layer' do
      should be_able_to(:index_people, groups(:toppers))
      should be_able_to(:index_full_people, groups(:toppers))
      should be_able_to(:index_local_people, groups(:toppers))
    end
  end


  describe :contact_data do
    let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }

    it 'may view details of himself' do
      should be_able_to(:show_full, role.person.reload)
    end

    it 'may modify himself' do
      should be_able_to(:update, role.person.reload)
    end

    it 'may not modify his role' do
      should_not be_able_to(:update, role)
    end

    it 'may not create other users' do
      should_not be_able_to(:create, Person)
    end

    it 'may view others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      should be_able_to(:show, other.person.reload)
    end

    it 'may view details of others in same group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      should be_able_to(:show_details, other.person.reload)
    end
    it 'may not view full of others in same group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify others in same group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:update, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may show any public role in same layer' do
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers))
      should be_able_to(:show, other.person.reload)
    end

    it 'may not view details of public role in same layer' do
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers))
      should_not be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify any role in same layer' do
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers))
      should_not be_able_to(:update, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not view externals in other group of same layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:toppers))
      should_not be_able_to(:show, other.person.reload)
    end

    it 'may view any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      should be_able_to(:show, other.person.reload)
    end

    it 'may not modify any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:update, other.person.reload)
      should_not be_able_to(:update, other)
    end

    it 'may not view any externals in groups below' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      should_not be_able_to(:show, other.person.reload)
    end

    it 'may index own group' do
      should be_able_to(:index_people, groups(:top_group))
      should be_able_to(:index_local_people, groups(:top_group))
      should_not be_able_to(:index_full_people, groups(:top_group))
    end

    it 'may index groups anywhere' do
      should be_able_to(:index_people, groups(:bottom_group_one_one))
      should_not be_able_to(:index_full_people, groups(:bottom_group_one_one))
      should_not be_able_to(:index_local_people, groups(:bottom_group_one_one))
    end

  end

  describe :group_full do
    let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }

    it 'may view details of himself' do
      should be_able_to(:show_full, role.person.reload)
    end

    it 'may update himself' do
      should be_able_to(:update, role.person.reload)
      should be_able_to(:update_email, role.person)
    end

    it 'may update her email with password' do
      himself = role.person.reload
      himself.encrypted_password = 'foooo'
      should be_able_to(:update_email, himself)
    end

    it 'may update his role' do
      should be_able_to(:update, role)
    end

    it 'may create other users' do
      should be_able_to(:create, Person)
    end

    it 'may view and update others in same group' do
      other = Fabricate(:person, password: 'foobar', password_confirmation: 'foobar')
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: other)
      should be_able_to(:show, other.reload)
      should be_able_to(:update, other)
      should be_able_to(:update_email, other)
    end

    it 'may not update email for person in other group' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two), person: other.person)
      should be_able_to(:update, other.person.reload)
      should_not be_able_to(:update_email, other.person)
    end

    it 'may not update email for person in other group if group_full everywhere' do
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_two), person: role.person)
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may update email for person with uncapable role in other group' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_two), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may update email for uncapable person with uncapable role in other group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_two), person: other.person)
      should be_able_to(:update, other.person.reload)
      should be_able_to(:update_email, other.person)
    end

    it 'may not update email for uncapable person with role in other group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two), person: other.person)
      should be_able_to(:update, other.person.reload)
      should_not be_able_to(:update_email, other.person)
    end

    it 'may not update root email if in same group' do
      root = people(:root)
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: root)
      should be_able_to(:update, root.reload)
      should_not be_able_to(:update_email, root)
    end

    it 'may view and update externals in same group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one))
      should be_able_to(:show, other.person.reload)
      should be_able_to(:update, other.person)
      should be_able_to(:update_email, other.person)
    end

    it 'may view details of others in same group' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      should be_able_to(:show_details, other.person.reload)
    end

    it 'may view full of others in same group' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      should be_able_to(:show_full, other.person.reload)
    end

    it 'may not view public role in same layer' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two))
      should_not be_able_to(:show, other.person.reload)
    end

    it 'may index same group' do
      should be_able_to(:index_people, groups(:bottom_group_one_one))
      should be_able_to(:index_local_people, groups(:bottom_group_one_one))
      should be_able_to(:index_full_people, groups(:bottom_group_one_one))
    end

    it 'may not index groups in same layer' do
      should_not be_able_to(:index_people, groups(:bottom_group_one_two))
      should_not be_able_to(:index_full_people, groups(:bottom_group_one_two))
      should_not be_able_to(:index_local_people, groups(:bottom_group_one_two))
    end
  end

  describe :group_read do
    let(:role) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)) }

    it 'may view details of himself' do
      should be_able_to(:show_full, role.person.reload)
    end

    it 'may update himself' do
      should be_able_to(:update, role.person.reload)
      should be_able_to(:update_email, role.person)
    end

    it 'may not update his role' do
      should_not be_able_to(:update, role)
    end

    it 'may not create other users' do
      should_not be_able_to(:create, Person)
    end

    it 'may view others in same group' do
      other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
      should be_able_to(:show, other.person.reload)
    end

    it 'may view externals in same group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one))
      should be_able_to(:show, other.person.reload)
    end

    it 'may view details of others in same group' do
      other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
      should be_able_to(:show_details, other.person.reload)
    end

    it 'may not view full of others in same group' do
      other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
      should_not be_able_to(:show_full, other.person.reload)
    end

    it 'may not view public role in same layer' do
      other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_two))
      should_not be_able_to(:show, other.person.reload)
    end

    it 'may index same group' do
      should be_able_to(:index_people, groups(:bottom_group_one_one))
      should be_able_to(:index_local_people, groups(:bottom_group_one_one))
      should_not be_able_to(:index_full_people, groups(:bottom_group_one_one))
    end

    it 'may not index groups in same layer' do
      should_not be_able_to(:index_people, groups(:bottom_group_one_two))
      should_not be_able_to(:index_full_people, groups(:bottom_group_one_two))
      should_not be_able_to(:index_local_people, groups(:bottom_group_one_two))
    end
  end

  describe 'no permissions' do
    let(:role) { Fabricate(Role::External.name.to_sym, group: groups(:top_group)) }

    it 'may view details of himself' do
      should be_able_to(:show_full, role.person.reload)
    end

    it 'may modify himself' do
      should be_able_to(:update, role.person.reload)
      should be_able_to(:update_email, role.person)
    end

    it 'may not modify his role' do
      should_not be_able_to(:update, role)
    end

    it 'may not create other users' do
      should_not be_able_to(:create, Person)
    end

    it 'may not view others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:show, other.person.reload)
    end

    it 'may not view externals in same group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:show, other.person.reload)
    end

    it 'may not view details of others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:show_details, other.person.reload)
    end

    it 'may not view full of others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      should_not be_able_to(:show_full, other.person.reload)
    end

    it 'may not view public role in same layer' do
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers))
      should_not be_able_to(:show, other.person.reload)
    end

    it 'may index same group' do
      should_not be_able_to(:index_people, groups(:top_group))
      should_not be_able_to(:index_local_people, groups(:top_group))
      should_not be_able_to(:index_full_people, groups(:top_group))
    end

    it 'may not index groups in same layer' do
      should_not be_able_to(:index_people, groups(:top_layer))
      should_not be_able_to(:index_full_people, groups(:top_layer))
      should_not be_able_to(:index_local_people, groups(:top_layer))
    end
  end

  describe 'root' do
    let(:user) { people(:root) }
    let(:ability) { Ability.new(user) }


    it 'may not change her email' do
      should_not be_able_to(:update_email, user)
    end
  end

  describe 'people filter' do

    context 'root layer and below full' do
      let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

      context 'in group from same layer' do
        let(:group) { groups(:top_group) }

        it 'may create people filters' do
          should be_able_to(:create, group.people_filters.new)
        end
      end

      context 'in group from lower layer' do
        let(:group) { groups(:bottom_layer_one) }

        it 'may not create people filters' do
          should_not be_able_to(:create, group.people_filters.new)
        end

        it 'may define new people filters' do
          should be_able_to(:new, group.people_filters.new)
        end
      end
    end

    context 'bottom layer and below full' do
      let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }

      context 'in group from same layer' do
        let(:group) { groups(:bottom_layer_one) }

        it 'may create people filters' do
          should be_able_to(:create, group.people_filters.new)
        end
      end

      context 'in group from upper layer' do
        let(:group) { groups(:top_layer) }

        it 'may not create people filters' do
          should_not be_able_to(:create, group.people_filters.new)
        end

        it 'may define new people filters' do
          should be_able_to(:new, group.people_filters.new)
        end
      end
    end

    context 'layer and below read' do
      let(:role) { Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)) }

      context 'in group from same layer' do
        let(:group) { groups(:top_group) }

        it 'may not create people filters' do
          should_not be_able_to(:create, group.people_filters.new)
        end

        it 'may define new people filters' do
          should be_able_to(:new, group.people_filters.new)
        end
      end

      context 'in group from lower layer' do
        let(:group) { groups(:bottom_layer_one) }

        it 'may not create people filters' do
          should_not be_able_to(:create, group.people_filters.new)
        end

        it 'may define new people filters' do
          should be_able_to(:new, group.people_filters.new)
        end
      end
    end
  end

  describe :show_details do
    let(:other) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person.reload }

    context 'layer and below full' do
      let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }
      it 'can show_details' do
        should be_able_to(:show_details, other)
        should be_able_to(:show_full, other)
      end
    end

    context 'same group' do
      let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }
      it 'can show_details' do
        should be_able_to(:show_details, other)
        should_not be_able_to(:show_full, other)
      end
    end

    context 'group below' do
      let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }
      it 'cannot show_details' do
        should_not be_able_to(:show_details, other)
        should_not be_able_to(:show_full, other)
      end
    end
  end

  describe :send_password_instructions do
    let(:other) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person.reload }

    context 'layer and below full' do
      let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }
      it 'can send_password_instructions' do
        should be_able_to(:send_password_instructions, other)
      end

      it 'can send_password_instructions for external role' do
        external = Fabricate(Role::External.name.to_sym, group: groups(:top_group)).person.reload
        should be_able_to(:send_password_instructions, external)
      end

      it 'cannot send_password_instructions for self' do
        should_not be_able_to(:send_password_instructions, role.person.reload)
      end
    end

    context 'same group' do
      let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }
      it 'cannot send_password_instructions' do
        should_not be_able_to(:send_password_instructions, other)
      end
    end

    context 'group below' do
      let(:role) { Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)) }
      it 'cannot send_password_instructions' do
        should_not be_able_to(:send_password_instructions, other)
      end
    end
  end

end
