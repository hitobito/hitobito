#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Role::List do
  let(:role_list) { Role::List.new(ability, params) }
  let(:ability) { Ability.new(person) }
  let(:params) { {} }
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let!(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group) }

  context "build_new_roles_hash" do
    let(:params) { ActionController::Parameters.new({ids: person.id,
                                                     role: {type: "Group::TopGroup::Leader",
                                                            group_id: group.id}}) }

    it "throws access denied error if authorizaion fils" do
      allow(ability).to receive(:can?).and_return(false)

      expect do
        role_list.build_new_roles_hash
      end.to raise_error(CanCan::AccessDenied, "Zugriff auf Top Leader verweigert")
    end
  end

  context "available role types" do
    before do
      Fabricate(Group::TopGroup::Member.name.to_sym, group: group)
      Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers))
      Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
    end

    it "builds correct hash for one group" do
      allow(role_list).to receive(:roles).and_return(group.roles)

      available_role_types = role_list.collect_available_role_types

      group = available_role_types["TopGroup"]
      expect(group["Group::TopGroup::Leader"]).to eq(1)
      expect(group["Group::TopGroup::Member"]).to eq(2)
    end

    it "builds correct hash for multiple groups" do
      allow(role_list).to receive(:roles).
        and_return(group.roles + groups(:toppers).roles)

      available_role_types = role_list.collect_available_role_types

      group1 = available_role_types["TopGroup"]
      expect(group1["Group::TopGroup::Leader"]).to eq(1)
      expect(group1["Group::TopGroup::Member"]).to eq(2)

      group2 = available_role_types["Toppers"]
      expect(group2["Group::GlobalGroup::Member"]).to eq(1)
    end

    it "does not add role to hash if no access" do
      allow(role_list).to receive(:roles).and_return(group.roles)
      allow(ability).to receive(:can?).and_call_original
      allow(ability).to receive(:can?).with(:destroy, role).and_return(false)

      available_role_types = role_list.collect_available_role_types

      group = available_role_types["TopGroup"]
      expect(group["Group::TopGroup::Leader"]).to eq(1)
      expect(group["Group::TopGroup::Member"]).to eq(1)
    end
  end
end
