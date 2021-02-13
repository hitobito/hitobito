# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe AbilityDsl::UserContext do
  subject { AbilityDsl::UserContext.new(user) }

  context :top_leader do
    let(:user) { people(:top_leader) }

    it { expect(subject.permission_group_ids(:group_full)).to eq [] }
    it { expect(subject.permission_group_ids(:group_read)).to eq [] }
    it { expect(subject.permission_group_ids(:layer_and_below_full)).to eq [groups(:top_group).id] }
    it { expect(subject.permission_group_ids(:layer_and_below_read)).to eq [groups(:top_group).id] }
    it { expect(subject.permission_layer_ids(:layer_and_below_full)).to eq [groups(:top_layer).id] }
    it { expect(subject.permission_layer_ids(:layer_and_below_read)).to eq [groups(:top_layer).id] }
    its(:admin) { should be_truthy }
    its(:all_permissions) { is_expected.to contain_exactly(:admin, :finance, :impersonation, :layer_and_below_full, :layer_and_below_read, :contact_data) }

    it "has no events with permission full" do
      expect(subject.events_with_permission(:event_full)).to be_blank
    end
  end

  context :bottom_member do
    let(:user) { people(:bottom_member) }

    it { expect(subject.permission_group_ids(:group_full)).to eq [] }
    it { expect(subject.permission_group_ids(:group_read)).to eq [] }
    it { expect(subject.permission_group_ids(:layer_and_below_full)).to eq [] }
    it { expect(subject.permission_group_ids(:layer_and_below_read)).to eq [groups(:bottom_layer_one).id] }
    it { expect(subject.permission_layer_ids(:layer_and_below_full)).to eq [] }
    it { expect(subject.permission_layer_ids(:layer_and_below_read)).to eq [groups(:bottom_layer_one).id] }
    its(:admin) { should be_falsey }
    its(:all_permissions) { is_expected.to eq [:layer_and_below_read, :finance] }

    it "has events with permission full" do
      expect(subject.events_with_permission(:event_full)).to match_array([events(:top_course).id])
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

    it { expect(subject.permission_group_ids(:group_full)).to eq [] }
    it { expect(subject.permission_group_ids(:group_read)).to eq [groups(:bottom_group_one_two).id] }
    it { expect(subject.permission_group_ids(:group_and_below_read)).to eq [groups(:top_group).id] }
    it { expect(subject.permission_group_ids(:layer_and_below_full)).to eq [groups(:bottom_layer_one).id] }
    it { expect(subject.permission_group_ids(:layer_and_below_read)).to eq [groups(:bottom_layer_one).id] }
    it { expect(subject.permission_layer_ids(:layer_and_below_full)).to eq [groups(:bottom_layer_one).id] }
    it { expect(subject.permission_layer_ids(:layer_and_below_read)).to eq [groups(:bottom_layer_one).id] }
    its(:admin) { should be_falsey }
    its(:all_permissions) { is_expected.to contain_exactly(:layer_and_below_full, :layer_and_below_read, :group_read, :group_and_below_read, :contact_data, :approve_applications) }
  end
end
