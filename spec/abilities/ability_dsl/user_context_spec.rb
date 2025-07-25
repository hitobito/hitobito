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
      Fabricate(Group::TopGroup::Leader.sti_name.to_sym, group: groups(:top_group), person: p, start_on: 3.years.ago, end_on: 2.years.ago)
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

  describe "permission implication for groups" do
    let!(:group_a) { Fabricate(Group::StaticNameAGroup.sti_name.to_sym, parent: groups(:bottom_layer_one)) }
    let!(:group_b) { Fabricate(Group::StaticNameBGroup.sti_name.to_sym, parent: groups(:bottom_layer_one)) }

    let(:user) { people(:bottom_member) }

    describe "#all_permissions" do
      it "includes implicit permissions for groups" do
        stub_const("Role::Types::PermissionImplicationsForGroups", {
          finance: {
            invoices_full: Group::BottomGroup,
            invoices_read: Group::StaticNameBGroup
          },
          layer_and_below_read: {
            admin: Group::StaticNameBGroup
          }
        })
        expect(subject.all_permissions).to contain_exactly(:finance, :layer_and_below_read, :invoices_full, :invoices_read, :admin)
      end

      it "includes implicit permissions expanded with implications" do
        # Let's implicate :group_and_below_full from :layer_and_below_read. This should include :group_and_below_read as well
        # as this is defined on `Role::Types::PermissionImplications`.
        stub_const("Role::Types::PermissionImplicationsForGroups",
          {layer_and_below_read: {group_and_below_full: Group::BottomGroup}})
        expect(subject.all_permissions).to contain_exactly(:finance, :layer_and_below_read, :group_and_below_full, :group_and_below_read)
      end
    end

    describe "#permission_group_ids(:permission)" do
      it "includes implicit permissions for groups" do
        stub_const("Role::Types::PermissionImplicationsForGroups", {
          finance: {
            invoices_full: Group::BottomGroup,
            invoices_read: Group::StaticNameAGroup
          },
          layer_and_below_read: {
            group_and_below_full: Group::StaticNameBGroup
          }
        })

        # finance is directly granted by the Member role on bottom_layer_one
        # see `Group::BottomLayer::Member`
        expect(subject.permission_group_ids(:finance)).to eq [groups(:bottom_layer_one).id]

        # invoices_full is implicitely granted for all BottomGroup in the layer by the finance permission
        # see test setup
        expect(subject.permission_group_ids(:invoices_full)).to match_array([groups(:bottom_group_one_one).id, groups(:bottom_group_one_one_one).id, groups(:bottom_group_one_two).id])

        # invoices_read is implicitely granted for all StaticNameAGroup in the layer by the finance permission
        # see test setup
        expect(subject.permission_group_ids(:invoices_read)).to eq [group_a.id]

        # group_and_below_full is implicitely granted for all StaticNameBGroup in the layer by the layer_and_below_read permission
        # see test setup
        expect(subject.permission_group_ids(:group_and_below_full)).to eq [group_b.id]

        # group_and_below_read is implicitely granted on the same group by the group_and_below_full permission
        # see `Role::Types::PermissionImplications`
        expect(subject.permission_group_ids(:group_and_below_read)).to eq [group_b.id]
      end
    end
  end
end
