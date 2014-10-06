# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe AbilityDsl::UserContext do

  subject { AbilityDsl::UserContext.new(user) }

  context :top_leader do
    let(:user) { people(:top_leader) }

    its(:groups_group_full) { should =~ [] }
    its(:groups_group_read) { should =~ [] }
    its(:groups_layer_and_below_full) { should =~ [groups(:top_group).id] }
    its(:groups_layer_and_below_read) { should =~ [groups(:top_group).id] }
    its(:layers_and_below_full)       { should =~ [groups(:top_layer).id] }
    its(:layers_and_below_read)       { should =~ [groups(:top_layer).id] }
    its(:admin)             { should be_true }
    its(:all_permissions)   { should =~ [:admin, :layer_and_below_full, :layer_and_below_read, :contact_data] }

    it 'has no events with permission full' do
      subject.events_with_permission(:event_full).should be_blank
    end
  end

  context :bottom_member do
    let(:user) { people(:bottom_member) }

    its(:groups_group_full) { should =~ [] }
    its(:groups_group_read) { should =~ [] }
    its(:groups_layer_and_below_full) { should =~ [] }
    its(:groups_layer_and_below_read) { should =~ [groups(:bottom_layer_one).id] }
    its(:layers_and_below_full)       { should =~ [] }
    its(:layers_and_below_read)       { should =~ [groups(:bottom_layer_one).id] }
    its(:admin)             { should be_false }
    its(:all_permissions)   { should =~ [:layer_and_below_read] }

    it 'has events with permission full' do
      subject.events_with_permission(:event_full).should =~ [events(:top_course).id]
    end
  end

  context :multiple_roles do
    let(:user) do
      p = Fabricate(:person)
      Fabricate(Group::TopGroup::Member.sti_name.to_sym, group: groups(:top_group), person: p)
      Fabricate(Group::BottomLayer::Leader.sti_name.to_sym, group: groups(:bottom_layer_one), person: p)
      Fabricate(Group::BottomGroup::Member.sti_name.to_sym, group: groups(:bottom_group_one_two), person: p)
      Fabricate(Role::External.sti_name.to_sym, group: groups(:bottom_group_one_two), person: p)
      Fabricate(Group::TopGroup::Leader.sti_name.to_sym, group: groups(:top_group), person: p, deleted_at: 2.years.ago)
      p
    end

    its(:groups_group_full) { should =~ [] }
    its(:groups_group_read) { should =~ [groups(:top_group).id, groups(:bottom_group_one_two).id] }
    its(:groups_layer_and_below_full) { should =~ [groups(:bottom_layer_one).id] }
    its(:groups_layer_and_below_read) { should =~ [groups(:bottom_layer_one).id] }
    its(:layers_and_below_full)       { should =~ [groups(:bottom_layer_one).id] }
    its(:layers_and_below_read)       { should =~ [groups(:bottom_layer_one).id] }
    its(:admin)             { should be_false }
    its(:all_permissions)   { should =~ [:layer_and_below_full, :layer_and_below_read, :group_read, :contact_data, :approve_applications] }
  end

end
