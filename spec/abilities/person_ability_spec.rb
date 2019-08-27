# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PersonAbility do

  subject { ability }
  let(:ability) { Ability.new(role.person.reload) }

  context :layer_and_below_full do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'may modify any public role in lower layers' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
      is_expected.to be_able_to(:update, other)
    end

    it 'may not update root email if in same group' do
      root = people(:root)
      Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group), person: root)
      is_expected.to be_able_to(:update, root.reload)
      is_expected.not_to be_able_to(:update_email, root)
    end

    it 'may modify its role' do
      is_expected.to be_able_to(:update, role)
    end

    it 'may modify its password' do
      is_expected.to be_able_to(:update_email, role.person)
    end

    it 'may not destroy its role' do
      is_expected.not_to be_able_to(:destroy, role)
    end

    it 'may modify externals in the same layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_layer))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
      is_expected.to be_able_to(:update, other)
    end

    it 'may not view any non-visible in lower layers' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not view any externals in lower layers' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may index groups in lower layer' do
      is_expected.to be_able_to(:index_people, groups(:bottom_layer_one))
      is_expected.to be_able_to(:index_full_people, groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may index groups in same layer' do
      is_expected.to be_able_to(:index_people, groups(:top_layer))
      is_expected.to be_able_to(:index_full_people, groups(:top_layer))
      is_expected.to be_able_to(:index_local_people, groups(:top_layer))
    end

    it 'may show notes and tags in same layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:index_notes, other.person.reload)
      is_expected.to be_able_to(:index_tags, other.person.reload)
      is_expected.to be_able_to(:manage_tags, other.person.reload)
    end

    it 'may show notes and tags in lower layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.to be_able_to(:index_notes, other.person.reload)
      is_expected.to be_able_to(:index_tags, other.person.reload)
      is_expected.to be_able_to(:manage_tags, other.person.reload)
    end
  end

  describe 'layer_and_below_full in bottom layer' do
    let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }

    it 'may create other users' do
      is_expected.to be_able_to(:create, Person)
    end

    it 'may modify its role' do
      is_expected.to be_able_to(:update, role)
    end

    it 'may not destroy its role' do
      is_expected.not_to be_able_to(:destroy, role)
    end

    it 'may modify any public role in same layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym,
                        group: groups(:bottom_layer_one),
                        person: Fabricate(:person, password: 'foobar', password_confirmation: 'foobar'))
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
      is_expected.to be_able_to(:update, other)
      is_expected.to be_able_to(:create, other)
      is_expected.to be_able_to(:destroy, other)
    end

    it 'may not view any public role in upper layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not update email for person with role in upper layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update_email, other.person)
    end

    it 'may not view any public role in other layer' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not update email for person with role in other layer' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update_email, other.person)
    end

    it 'may update email for person with role in other layer if layer_and_below_full there' do
      Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two), person: role.person)
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may update email for person with role in other group if group_full there' do
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one), person: role.person)
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_two_one))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may update email for person with uncapable role in upper layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may update email for person with uncapable role in other layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may update email for uncapable person with uncapable role in other layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may not update email for uncapable person with role in other layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update_email, other.person)
    end

    it 'may modify externals in his layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update, other)
      is_expected.to be_able_to(:create, other)
      is_expected.to be_able_to(:destroy, other)
    end

    it 'may modify children in his layer' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
      is_expected.to be_able_to(:update, other)
      is_expected.to be_able_to(:create, other)
      is_expected.to be_able_to(:destroy, other)
    end

    it 'may not view any externals in upper layers' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may index groups in upper layer' do
      is_expected.to be_able_to(:index_people, groups(:top_layer))
      is_expected.not_to be_able_to(:index_full_people, groups(:top_layer))
      is_expected.not_to be_able_to(:index_local_people, groups(:top_layer))
    end

    it 'may index groups in same layer' do
      is_expected.to be_able_to(:index_people, groups(:bottom_layer_one))
      is_expected.to be_able_to(:index_full_people, groups(:bottom_layer_one))
      is_expected.to be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may show notes and tags in same layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.to be_able_to(:index_notes, other.person.reload)
      is_expected.to be_able_to(:index_tags, other.person.reload)
      is_expected.to be_able_to(:manage_tags, other.person.reload)
    end

    it 'may show notes and tags in lower group' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:index_notes, other.person.reload)
      is_expected.to be_able_to(:index_tags, other.person.reload)
      is_expected.to be_able_to(:manage_tags, other.person.reload)
    end

    it 'may not show notes and tags in uppper layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:index_tags, other.person.reload)
      is_expected.not_to be_able_to(:manage_tags, other.person.reload)
    end
  end

  context :layer_and_below_read do
    # member with additional group_full role
    let(:role)       { Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)) }

    it 'may view details of himself' do
      is_expected.to be_able_to(:show_full, role.person.reload)
    end

    it 'may modify himself' do
      is_expected.to be_able_to(:update, role.person.reload)
    end

    it 'may modify its read role' do
      is_expected.to be_able_to(:update, role)
    end

    it 'may not destroy its role' do
      is_expected.not_to be_able_to(:destroy, role)
    end

    it 'may create other users as group admin' do
      is_expected.to be_able_to(:create, Person)
    end

    it 'may view any public role in same layer' do
      other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers))
      is_expected.to be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify any role in same layer' do
      other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers))
      is_expected.not_to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may view any externals in same layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:toppers))
      is_expected.to be_able_to(:show_full, other.person.reload)
    end

    it 'may modify any role in same group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update, other)
    end

    it 'may view any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.to be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not view any externals in groups below' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may index groups in lower layer' do
      is_expected.to be_able_to(:index_people, groups(:bottom_layer_one))
      is_expected.to be_able_to(:index_full_people, groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may index groups in same layer' do
      is_expected.to be_able_to(:index_people, groups(:toppers))
      is_expected.to be_able_to(:index_full_people, groups(:toppers))
      is_expected.to be_able_to(:index_local_people, groups(:toppers))
    end
  end

  context :layer_full do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

    it 'may not modify any public role in lower layers' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not update root email if in same group' do
      root = people(:root)
      Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group), person: root)
      is_expected.to be_able_to(:update, root.reload)
      is_expected.not_to be_able_to(:update_email, root)
    end

    it 'may modify its role' do
      is_expected.to be_able_to(:update, role)
    end

    it 'may modify its password' do
      is_expected.to be_able_to(:update_email, role.person)
    end

    it 'may not destroy its role' do
      is_expected.not_to be_able_to(:destroy, role)
    end

    it 'may modify externals in the same layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_layer))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
      is_expected.to be_able_to(:update, other)
    end

    it 'may not view any non-visible in lower layers' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.not_to be_able_to(:show, other.person.reload)
      is_expected.not_to be_able_to(:show_full, other.person)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not view any non-contact data in lower layers' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:show, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not view any externals in lower layers' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:show, other.person.reload)
      is_expected.not_to be_able_to(:show_full, other.person)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not index groups in lower layer' do
      is_expected.not_to be_able_to(:index_people, groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_full_people, groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may index groups in same layer' do
      is_expected.to be_able_to(:index_people, groups(:top_layer))
      is_expected.to be_able_to(:index_full_people, groups(:top_layer))
      is_expected.to be_able_to(:index_local_people, groups(:top_layer))
    end

    it 'may show notes and tags in same layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:index_notes, other.person.reload)
      is_expected.to be_able_to(:index_tags, other.person.reload)
      is_expected.to be_able_to(:manage_tags, other.person.reload)
    end

    it 'may not show notes and tags in lower layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_notes, other.person.reload)
      is_expected.not_to be_able_to(:index_tags, other.person.reload)
      is_expected.not_to be_able_to(:manage_tags, other.person.reload)
    end
  end

  describe 'layer_full in bottom layer' do
    let(:role) { Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_one)) }

    it 'may create other users' do
      is_expected.to be_able_to(:create, Person)
    end

    it 'may modify its role' do
      is_expected.to be_able_to(:update, role)
    end

    it 'may not destroy its role' do
      is_expected.not_to be_able_to(:destroy, role)
    end

    it 'may modify any public role in same layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym,
                        group: groups(:bottom_layer_one),
                        person: Fabricate(:person, password: 'foobar', password_confirmation: 'foobar'))
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
      is_expected.to be_able_to(:update, other)
      is_expected.to be_able_to(:create, other)
      is_expected.to be_able_to(:destroy, other)
    end

    it 'may not view any public role in upper layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not update email for person with role in upper layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update_email, other.person)
    end

    it 'may not view any public role in other layer' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not view any private role in other layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_two))
      is_expected.not_to be_able_to(:show, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not update email for person with role in other layer' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update_email, other.person)
    end

    it 'may update email for person with role in other layer if layer_full there' do
      Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_two), person: role.person)
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may update email for person with role in other group if group_full there' do
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one), person: role.person)
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_two_one))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may update email for person with uncapable role in upper layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may update email for person with uncapable role in other layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may update email for uncapable person with uncapable role in other layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may not update email for uncapable person with role in other layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_two))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update_email, other.person)
    end

    it 'may modify externals in his layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update, other)
      is_expected.to be_able_to(:create, other)
      is_expected.to be_able_to(:destroy, other)
    end

    it 'may modify children in his layer' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
      is_expected.to be_able_to(:update, other)
      is_expected.to be_able_to(:create, other)
      is_expected.to be_able_to(:destroy, other)
    end

    it 'may not view any externals in upper layers' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may index groups in upper layer' do
      is_expected.not_to be_able_to(:index_people, groups(:top_layer))
      is_expected.not_to be_able_to(:index_full_people, groups(:top_layer))
      is_expected.not_to be_able_to(:index_local_people, groups(:top_layer))
    end

    it 'may index groups in same layer' do
      is_expected.to be_able_to(:index_people, groups(:bottom_layer_one))
      is_expected.to be_able_to(:index_full_people, groups(:bottom_layer_one))
      is_expected.to be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may show notes and tags in same layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.to be_able_to(:index_notes, other.person.reload)
      is_expected.to be_able_to(:index_tags, other.person.reload)
      is_expected.to be_able_to(:manage_tags, other.person.reload)
    end

    it 'may show notes and tags in lower group' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:index_notes, other.person.reload)
      is_expected.to be_able_to(:index_tags, other.person.reload)
      is_expected.to be_able_to(:manage_tags, other.person.reload)
    end

    it 'may not show notes and tags in upper layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:index_notes, other.person.reload)
      is_expected.not_to be_able_to(:index_tags, other.person.reload)
      is_expected.not_to be_able_to(:manage_tags, other.person.reload)
    end
  end

  context :layer_read do
    let(:role) { Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: groups(:top_group)) }

    it 'may view details of himself' do
      is_expected.to be_able_to(:show_full, role.person.reload)
    end

    it 'may modify himself' do
      is_expected.to be_able_to(:update, role.person.reload)
    end

    it 'may modify its read role' do
      is_expected.not_to be_able_to(:update, role)
    end

    it 'may not destroy its role' do
      is_expected.not_to be_able_to(:destroy, role)
    end

    it 'may create other users as group admin' do
      is_expected.not_to be_able_to(:create, Person)
    end

    it 'may view any public role in same layer' do
      other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers))
      is_expected.to be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify any role in same layer' do
      other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers))
      is_expected.not_to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may view any externals in same layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:toppers))
      is_expected.to be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify any role in same group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not view any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may not modify any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not view any externals in groups below' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may index groups in lower layer' do
      is_expected.not_to be_able_to(:index_people, groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_full_people, groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may index people same layer' do
      is_expected.to be_able_to(:index_people, groups(:top_layer))
      is_expected.to be_able_to(:index_full_people, groups(:top_layer))
      is_expected.to be_able_to(:index_local_people, groups(:top_layer))
    end

    it 'may index people in groups in same layer' do
      is_expected.to be_able_to(:index_people, groups(:toppers))
      is_expected.to be_able_to(:index_full_people, groups(:toppers))
      is_expected.to be_able_to(:index_local_people, groups(:toppers))
    end

    it 'may not show notes and tags in same layer' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:index_notes, other.person.reload)
      is_expected.not_to be_able_to(:index_tags, other.person.reload)
      is_expected.not_to be_able_to(:manage_tags, other.person.reload)
    end

    it 'may not show notes and tags in lower layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_notes, other.person.reload)
      is_expected.not_to be_able_to(:index_tags, other.person.reload)
      is_expected.not_to be_able_to(:manage_tags, other.person.reload)
    end
  end

  context :contact_data do
    let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }

    it 'may view details of himself' do
      is_expected.to be_able_to(:show_full, role.person.reload)
    end

    it 'may modify himself' do
      is_expected.to be_able_to(:update, role.person.reload)
    end

    it 'may not modify his role' do
      is_expected.not_to be_able_to(:update, role)
    end

    it 'may not create other users' do
      is_expected.not_to be_able_to(:create, Person)
    end

    it 'may view others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:show, other.person.reload)
    end

    it 'may view details of others in same group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:show_details, other.person.reload)
    end
    it 'may not view full of others in same group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify others in same group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may show any public role in same layer' do
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers))
      is_expected.to be_able_to(:show, other.person.reload)
    end

    it 'may not view details of public role in same layer' do
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
    end

    it 'may not modify any role in same layer' do
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers))
      is_expected.not_to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not view externals in other group of same layer' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:toppers))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may view any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.to be_able_to(:show, other.person.reload)
    end

    it 'may not modify any public role in groups below' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update, other)
    end

    it 'may not view any externals in groups below' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may index own group' do
      is_expected.to be_able_to(:index_people, groups(:top_group))
      is_expected.to be_able_to(:index_local_people, groups(:top_group))
      is_expected.not_to be_able_to(:index_full_people, groups(:top_group))
    end

    it 'may index groups anywhere' do
      is_expected.to be_able_to(:index_people, groups(:bottom_group_one_one))
      is_expected.not_to be_able_to(:index_full_people, groups(:bottom_group_one_one))
      is_expected.not_to be_able_to(:index_local_people, groups(:bottom_group_one_one))
    end
  end

  context :group_and_below_full do
    let(:role) { Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: groups(:top_layer)) }

    it 'may view details of himself' do
      is_expected.to be_able_to(:show_full, role.person.reload)
    end

    it 'may update himself' do
      is_expected.to be_able_to(:update, role.person.reload)
      is_expected.to be_able_to(:update_email, role.person)
    end

    it 'may update her email with password' do
      himself = role.person.reload
      himself.encrypted_password = 'foooo'
      is_expected.to be_able_to(:update_email, himself)
    end

    it 'may update his role' do
      is_expected.to be_able_to(:update, role)
    end

    it 'may create other users' do
      is_expected.to be_able_to(:create, Person)
    end

    it 'may view and update others in same group' do
      other = Fabricate(:person, password: 'foobar', password_confirmation: 'foobar')
      Fabricate(Role::External.name.to_sym, group: groups(:top_layer), person: other)
      is_expected.to be_able_to(:show, other.reload)
      is_expected.to be_able_to(:update, other)
      is_expected.to be_able_to(:update_email, other)
    end

    it 'may update email for person in below group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may not view and update email for person in below layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:show, other.person.reload)
      is_expected.not_to be_able_to(:update, other.person)
      is_expected.not_to be_able_to(:update_email, other.person)
    end

    it 'may not update email for person in same group and in below layer' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      Fabricate(Role::External.name.to_sym, group: groups(:top_layer), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update_email, other.person)
    end

    it 'may update email for person in below group if group_and_below_full everywhere' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_layer))
      Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may not update root email if in same group' do
      root = people(:root)
      Fabricate(Role::External.name.to_sym, group: groups(:top_layer), person: root)
      is_expected.to be_able_to(:update, root.reload)
      is_expected.not_to be_able_to(:update_email, root)
    end

    it 'may view and update externals in below group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:show, other.person.reload)
      is_expected.to be_able_to(:update, other.person)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may view details of others in below group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:show_details, other.person.reload)
    end

    it 'may view full of others in below group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:show_full, other.person.reload)
    end

    it 'may index same group' do
      is_expected.to be_able_to(:index_people, groups(:top_layer))
      is_expected.to be_able_to(:index_local_people, groups(:top_layer))
      is_expected.to be_able_to(:index_full_people, groups(:top_layer))
    end

    it 'may index below group' do
      is_expected.to be_able_to(:index_people, groups(:top_group))
      is_expected.to be_able_to(:index_local_people, groups(:top_group))
      is_expected.to be_able_to(:index_full_people, groups(:top_group))
    end

    it 'may not index groups in below layer' do
      is_expected.not_to be_able_to(:index_people, groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_full_people, groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_local_people, groups(:bottom_layer_one))
    end

    it 'may index and manage tags in same group' do
      other = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: groups(:top_layer))
      is_expected.to be_able_to(:index_tags, other.person.reload)
      is_expected.to be_able_to(:manage_tags, other.person.reload)
    end

    it 'may index and manage tags in below group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:index_tags, other.person.reload)
      is_expected.to be_able_to(:manage_tags, other.person.reload)
    end

    it 'may not index or manage tags in below layer' do
      other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_tags, other.person.reload)
      is_expected.not_to be_able_to(:manage_tags, other.person.reload)
    end
  end

  context :group_and_below_read do
    let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }

    it 'may view details of himself' do
      is_expected.to be_able_to(:show_full, role.person.reload)
    end

    it 'may update himself' do
      is_expected.to be_able_to(:update, role.person.reload)
      is_expected.to be_able_to(:update_email, role.person)
    end

    it 'may not update his role' do
      is_expected.not_to be_able_to(:update, role)
    end

    it 'may not create other users' do
      is_expected.not_to be_able_to(:create, Person)
    end

    it 'may view others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:show, other.person.reload)
    end

    it 'may view others in below group' do
      below = Fabricate(Group::GlobalGroup.name, parent: role.group)
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: below)
      is_expected.to be_able_to(:show, other.person.reload)
    end

    it 'may not view others in same layer' do
      other = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: groups(:top_layer))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may view externals in same group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:show, other.person.reload)
    end

    it 'may view externals in below group' do
      below = Fabricate(Group::GlobalGroup.name, parent: role.group)
      other = Fabricate(Role::External.name.to_sym, group: below)
      is_expected.to be_able_to(:show, other.person.reload)
    end

    it 'may view details of others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.to be_able_to(:show_details, other.person.reload)
    end

    it 'may view details of others in below group' do
      below = Fabricate(Group::GlobalGroup.name, parent: role.group)
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: below)
      is_expected.to be_able_to(:show_details, other.person.reload)
    end

    it 'may not view full of others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
    end

    it 'may not view full of others in same group' do
      below = Fabricate(Group::GlobalGroup.name, parent: role.group)
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: below)
      is_expected.not_to be_able_to(:show_full, other.person.reload)
    end

    it 'may index same group' do
      is_expected.to be_able_to(:index_people, groups(:top_group))
      is_expected.to be_able_to(:index_local_people, groups(:top_group))
      is_expected.not_to be_able_to(:index_full_people, groups(:top_group))
    end

    it 'may index below group' do
      below = Fabricate(Group::GlobalGroup.name, parent: role.group)
      is_expected.to be_able_to(:index_people, below)
      is_expected.to be_able_to(:index_local_people, below)
      is_expected.not_to be_able_to(:index_full_people, below)
    end

    it 'may not index groups in same layer' do
      is_expected.to be_able_to(:index_people, groups(:top_layer))
      is_expected.not_to be_able_to(:index_full_people, groups(:top_layer))
      is_expected.not_to be_able_to(:index_local_people, groups(:top_layer))
    end

    it 'may not index and manage tags in same group' do
      other = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: groups(:top_layer))
      is_expected.not_to be_able_to(:index_tags, other.person.reload)
      is_expected.not_to be_able_to(:manage_tags, other.person.reload)
    end

    it 'may not index and manage tags in below group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:index_tags, other.person.reload)
      is_expected.not_to be_able_to(:manage_tags, other.person.reload)
    end
  end

  context :group_full do
    let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }

    it 'may view details of himself' do
      is_expected.to be_able_to(:show_full, role.person.reload)
    end

    it 'may update himself' do
      is_expected.to be_able_to(:update, role.person.reload)
      is_expected.to be_able_to(:update_email, role.person)
    end

    it 'may update her email with password' do
      himself = role.person.reload
      himself.encrypted_password = 'foooo'
      is_expected.to be_able_to(:update_email, himself)
    end

    it 'may update his role' do
      is_expected.to be_able_to(:update, role)
    end

    it 'may create other users' do
      is_expected.to be_able_to(:create, Person)
    end

    it 'may view and update others in same group' do
      other = Fabricate(:person, password: 'foobar', password_confirmation: 'foobar')
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: other)
      is_expected.to be_able_to(:show, other.reload)
      is_expected.to be_able_to(:update, other)
      is_expected.to be_able_to(:update_email, other)
    end

    it 'may not update email for person in other group' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update_email, other.person)
    end

    it 'may update email for person in other group if group_full everywhere' do
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_two), person: role.person)
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may update email for person with uncapable role in other group' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_two), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may update email for uncapable person with uncapable role in other group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_two), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may not update email for uncapable person with role in other group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two), person: other.person)
      is_expected.to be_able_to(:update, other.person.reload)
      is_expected.not_to be_able_to(:update_email, other.person)
    end

    it 'may not update root email if in same group' do
      root = people(:root)
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: root)
      is_expected.to be_able_to(:update, root.reload)
      is_expected.not_to be_able_to(:update_email, root)
    end

    it 'may view and update externals in same group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:show, other.person.reload)
      is_expected.to be_able_to(:update, other.person)
      is_expected.to be_able_to(:update_email, other.person)
    end

    it 'may view details of others in same group' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:show_details, other.person.reload)
    end

    it 'may view full of others in same group' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:show_full, other.person.reload)
    end

    it 'may not view public role in same layer' do
      other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may index same group' do
      is_expected.to be_able_to(:index_people, groups(:bottom_group_one_one))
      is_expected.to be_able_to(:index_local_people, groups(:bottom_group_one_one))
      is_expected.to be_able_to(:index_full_people, groups(:bottom_group_one_one))
    end

    it 'may not index groups in same layer' do
      is_expected.not_to be_able_to(:index_people, groups(:bottom_group_one_two))
      is_expected.not_to be_able_to(:index_full_people, groups(:bottom_group_one_two))
      is_expected.not_to be_able_to(:index_local_people, groups(:bottom_group_one_two))
    end

    it 'may index and manage tags in same group' do
      other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:index_tags, other.person.reload)
      is_expected.to be_able_to(:manage_tags, other.person.reload)
    end
  end

  context :group_read do
    let(:role) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)) }

    it 'may view details of himself' do
      is_expected.to be_able_to(:show_full, role.person.reload)
    end

    it 'may update himself' do
      is_expected.to be_able_to(:update, role.person.reload)
      is_expected.to be_able_to(:update_email, role.person)
    end

    it 'may not update his role' do
      is_expected.not_to be_able_to(:update, role)
    end

    it 'may not create other users' do
      is_expected.not_to be_able_to(:create, Person)
    end

    it 'may view others in same group' do
      other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:show, other.person.reload)
    end

    it 'may view externals in same group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:show, other.person.reload)
    end

    it 'may view details of others in same group' do
      other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.to be_able_to(:show_details, other.person.reload)
    end

    it 'may not view full of others in same group' do
      other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
    end

    it 'may not view public role in same layer' do
      other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_two))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may index same group' do
      is_expected.to be_able_to(:index_people, groups(:bottom_group_one_one))
      is_expected.to be_able_to(:index_local_people, groups(:bottom_group_one_one))
      is_expected.not_to be_able_to(:index_full_people, groups(:bottom_group_one_one))
    end

    it 'may not index groups in same layer' do
      is_expected.not_to be_able_to(:index_people, groups(:bottom_group_one_two))
      is_expected.not_to be_able_to(:index_full_people, groups(:bottom_group_one_two))
      is_expected.not_to be_able_to(:index_local_people, groups(:bottom_group_one_two))
    end
  end

  context 'finance' do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'may not index in bottom layer group' do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
      is_expected.not_to be_able_to(:index_invoices, other)
    end

    it 'may index in top group' do
      other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:index_invoices, other)
    end
  end

  context 'impersonation' do
    let(:role) { people(:top_leader).roles.first }

    it 'may not impersonate user' do
      is_expected.to be_able_to(:impersonate_user, people(:bottom_member))
    end
  end

  describe 'no permissions' do
    let(:role) { Fabricate(Role::External.name.to_sym, group: groups(:top_group)) }

    it 'may view details of himself' do
      is_expected.to be_able_to(:show_full, role.person.reload)
    end

    it 'may view invoices of himself' do
      is_expected.to be_able_to(:index_invoices, role.person.reload)
    end

    it 'may modify himself' do
      is_expected.to be_able_to(:update, role.person.reload)
      is_expected.to be_able_to(:update_email, role.person)
    end

    it 'may not modify his role' do
      is_expected.not_to be_able_to(:update, role)
    end

    it 'may not create other users' do
      is_expected.not_to be_able_to(:create, Person)
    end

    it 'may not view others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may not view externals in same group' do
      other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may not view details of others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:show_details, other.person.reload)
    end

    it 'may not view full of others in same group' do
      other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
      is_expected.not_to be_able_to(:show_full, other.person.reload)
    end

    it 'may not view public role in same layer' do
      other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers))
      is_expected.not_to be_able_to(:show, other.person.reload)
    end

    it 'may index same group' do
      is_expected.not_to be_able_to(:index_people, groups(:top_group))
      is_expected.not_to be_able_to(:index_local_people, groups(:top_group))
      is_expected.not_to be_able_to(:index_full_people, groups(:top_group))
    end

    it 'may not index groups in same layer' do
      is_expected.not_to be_able_to(:index_people, groups(:top_layer))
      is_expected.not_to be_able_to(:index_full_people, groups(:top_layer))
      is_expected.not_to be_able_to(:index_local_people, groups(:top_layer))
    end
  end

  describe 'root' do
    let(:user) { people(:root) }
    let(:ability) { Ability.new(user) }


    it 'may not change her email' do
      is_expected.not_to be_able_to(:update_email, user)
    end
  end

  describe 'people filter' do

    context 'root layer and below full' do
      let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

      context 'in group from same layer' do
        let(:group) { groups(:top_group) }

        it 'may create people filters' do
          is_expected.to be_able_to(:create, group.people_filters.new)
        end
      end

      context 'in group from lower layer' do
        let(:group) { groups(:bottom_layer_one) }

        it 'may not create people filters' do
          is_expected.not_to be_able_to(:create, group.people_filters.new)
        end

        it 'may define new people filters' do
          is_expected.to be_able_to(:new, group.people_filters.new)
        end
      end
    end

    context 'bottom layer and below full' do
      let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }

      context 'in group from same layer' do
        let(:group) { groups(:bottom_layer_one) }

        it 'may create people filters' do
          is_expected.to be_able_to(:create, group.people_filters.new)
        end
      end

      context 'in group from upper layer' do
        let(:group) { groups(:top_layer) }

        it 'may not create people filters' do
          is_expected.not_to be_able_to(:create, group.people_filters.new)
        end

        it 'may define new people filters' do
          is_expected.to be_able_to(:new, group.people_filters.new)
        end
      end
    end

    context 'layer and below read' do
      let(:role) { Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)) }

      context 'in group from same layer' do
        let(:group) { groups(:top_group) }

        it 'may not create people filters' do
          is_expected.not_to be_able_to(:create, group.people_filters.new)
        end

        it 'may define new people filters' do
          is_expected.to be_able_to(:new, group.people_filters.new)
        end
      end

      context 'in group from lower layer' do
        let(:group) { groups(:bottom_layer_one) }

        it 'may not create people filters' do
          is_expected.not_to be_able_to(:create, group.people_filters.new)
        end

        it 'may define new people filters' do
          is_expected.to be_able_to(:new, group.people_filters.new)
        end
      end
    end
  end

  context :show_details do
    let(:other) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person.reload }

    context 'layer and below full' do
      let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }
      it 'can show_details' do
        is_expected.to be_able_to(:show_details, other)
        is_expected.to be_able_to(:show_full, other)
      end
    end

    context 'same group' do
      let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }
      it 'can show_details' do
        is_expected.to be_able_to(:show_details, other)
        is_expected.not_to be_able_to(:show_full, other)
      end
    end

    context 'group below' do
      let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }
      it 'cannot show_details' do
        is_expected.not_to be_able_to(:show_details, other)
        is_expected.not_to be_able_to(:show_full, other)
      end
    end
  end

  context :send_password_instructions do
    let(:other) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person.reload }

    context 'layer and below full' do
      let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }
      it 'can send_password_instructions' do
        is_expected.to be_able_to(:send_password_instructions, other)
      end

      it 'can send_password_instructions for external role' do
        external = Fabricate(Role::External.name.to_sym, group: groups(:top_group)).person.reload
        is_expected.to be_able_to(:send_password_instructions, external)
      end

      it 'cannot send_password_instructions for self' do
        is_expected.not_to be_able_to(:send_password_instructions, role.person.reload)
      end
    end

    context 'same group' do
      let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }
      it 'cannot send_password_instructions' do
        is_expected.not_to be_able_to(:send_password_instructions, other)
      end
    end

    context 'group below' do
      let(:role) { Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)) }
      it 'cannot send_password_instructions' do
        is_expected.not_to be_able_to(:send_password_instructions, other)
      end
    end
  end

end
