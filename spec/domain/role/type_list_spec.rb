#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Role::TypeList do
  it "contains all roles for top layer" do
    list = Role::TypeList.new(Group::TopLayer)
    expect(list.to_enum.to_a).to eq([
      ["Top Layer",
        {"Top Layer" => [Group::TopLayer::TopAdmin],
         "Top Group" => [Group::TopGroup::Leader, Group::TopGroup::LocalGuide,
           Group::TopGroup::Secretary, Group::TopGroup::LocalSecretary,
           Group::TopGroup::GroupManager, Group::TopGroup::Member,
           Group::TopGroup::InvisiblePeopleManager]}],

      ["Bottom Layer",
        {"Bottom Layer" => [Group::BottomLayer::Leader, Group::BottomLayer::LocalGuide,
          Group::BottomLayer::Member, Group::BottomLayer::BasicPermissionsOnly],
         "Bottom Group" => [Group::BottomGroup::Leader, Group::BottomGroup::Member]}],

      ["Global",
        {
          "Global Group" => [Group::GlobalGroup::Leader, Group::GlobalGroup::Member],
          "Global" => [Role::External]
        }]
    ])
  end

  it "contains all roles for bottom layer" do
    list = Role::TypeList.new(Group::BottomLayer)
    expect(list.to_enum.to_a).to eq([
      ["Bottom Layer",
        {"Bottom Layer" => [Group::BottomLayer::Leader, Group::BottomLayer::LocalGuide,
          Group::BottomLayer::Member, Group::BottomLayer::BasicPermissionsOnly],
         "Bottom Group" => [Group::BottomGroup::Leader, Group::BottomGroup::Member],
         "Global Group" => [Group::GlobalGroup::Leader, Group::GlobalGroup::Member]}],

      ["Global",
        {"Global" => [Role::External]}]
    ])
  end

  it "contains all roles for top group" do
    list = Role::TypeList.new(Group::TopGroup)
    expect(list.to_enum.to_a).to eq([
      ["Top Group",
        {"Top Group" => [Group::TopGroup::Leader, Group::TopGroup::LocalGuide,
          Group::TopGroup::Secretary, Group::TopGroup::LocalSecretary,
          Group::TopGroup::GroupManager, Group::TopGroup::Member,
          Group::TopGroup::InvisiblePeopleManager],
         "Global Group" => [Group::GlobalGroup::Leader, Group::GlobalGroup::Member]}],
      ["Global",
        {"Global" => [Role::External]}]
    ])
  end

  it "contains all roles for bottom group" do
    list = Role::TypeList.new(Group::BottomGroup)
    expect(list.to_enum.to_a).to eq([

      ["Bottom Group",
        {"Bottom Group" => [Group::BottomGroup::Leader, Group::BottomGroup::Member],
         "Global Group" => [Group::GlobalGroup::Leader, Group::GlobalGroup::Member]}],
      ["Global",
        {"Global" => [Role::External]}]
    ])
  end

  context "flattens the role list" do
    it "without block" do
      list = Role::TypeList.new(Group::TopLayer)
      expect(list.flatten.map(&:name)).to eq(%w[Group::TopLayer::TopAdmin Group::TopGroup::Leader
        Group::TopGroup::LocalGuide Group::TopGroup::Secretary Group::TopGroup::LocalSecretary
        Group::TopGroup::GroupManager Group::TopGroup::Member Group::TopGroup::InvisiblePeopleManager
        Group::BottomLayer::Leader Group::BottomLayer::LocalGuide Group::BottomLayer::Member
        Group::BottomLayer::BasicPermissionsOnly Group::BottomGroup::Leader
        Group::BottomGroup::Member Group::GlobalGroup::Leader Group::GlobalGroup::Member Role::External])
    end

    it "with block" do
      list = Role::TypeList.new(Group::TopLayer)
      expect(list.flatten { |r, g, l| {layer: l, group: g, role: r} }).to eq([
        {layer: "Top Layer", group: "Top Layer", role: Group::TopLayer::TopAdmin},
        {layer: "Top Layer", group: "Top Group", role: Group::TopGroup::Leader},
        {layer: "Top Layer", group: "Top Group", role: Group::TopGroup::LocalGuide},
        {layer: "Top Layer", group: "Top Group", role: Group::TopGroup::Secretary},
        {layer: "Top Layer", group: "Top Group", role: Group::TopGroup::LocalSecretary},
        {layer: "Top Layer", group: "Top Group", role: Group::TopGroup::GroupManager},
        {layer: "Top Layer", group: "Top Group", role: Group::TopGroup::Member},
        {layer: "Top Layer", group: "Top Group", role: Group::TopGroup::InvisiblePeopleManager},
        {layer: "Bottom Layer", group: "Bottom Layer", role: Group::BottomLayer::Leader},
        {layer: "Bottom Layer", group: "Bottom Layer", role: Group::BottomLayer::LocalGuide},
        {layer: "Bottom Layer", group: "Bottom Layer", role: Group::BottomLayer::Member},
        {layer: "Bottom Layer", group: "Bottom Layer", role: Group::BottomLayer::BasicPermissionsOnly},
        {layer: "Bottom Layer", group: "Bottom Group", role: Group::BottomGroup::Leader},
        {layer: "Bottom Layer", group: "Bottom Group", role: Group::BottomGroup::Member},
        {layer: "Global", group: "Global Group", role: Group::GlobalGroup::Leader},
        {layer: "Global", group: "Global Group", role: Group::GlobalGroup::Member},
        {layer: "Global", group: "Global", role: Role::External}
      ])
    end
  end

  describe "global groups and their children" do
    before do
      stub_const("Group::GlobalGroupChild::Member", Class.new(Role))
      stub_const("Group::GlobalGroupChild", Class.new(Group) do
        roles Group::GlobalGroupChild::Member
      end)
      allow(Group::GlobalGroup).to receive(:child_types).and_return([Group::GlobalGroup, Group::GlobalGroupChild])
    end

    it "lists children of global group" do
      list = Role::TypeList.new(Group::TopLayer)
      expect(list.to_enum.to_h["Global"].keys).to match_array(["Global Group", "Global", "Gruppe"])
    end
  end
end
