# frozen_string_literal true

require "rails_helper"
require_relative "../../app/utils/group_structure"

RSpec.describe GroupStructure do
  describe ".from_classes" do
    it "builds structure from Group classes" do
      structure = GroupStructure.from_classes
      expect(structure.root_nodes).to be_an(Array)
      expect(structure.root_nodes.first).to be_a(GroupStructure::GroupNode)
    end

    it "includes class information when built from classes" do
      structure = GroupStructure.from_classes
      structure.root_nodes.each do |node|
        expect(node.klass).not_to be_nil
      end
    end
  end

  describe ".parse" do
    let(:markdown) do
      <<~MARKDOWN
        ▲ = Layer group
        ¹ = Static group (only one can exist, name is predefined)

        * **▲Layer1**
          * _Role1: [:read] -- `RoleClass`_
        * **Group1**
          * _Role2: [:write]_
      MARKDOWN
    end

    it "parses markdown format" do
      structure = GroupStructure.parse(markdown)
      expect(structure.root_nodes).to be_an(Array)
      expect(structure.root_nodes.length).to eq(2)
    end

    it "parses layer markers" do
      structure = GroupStructure.parse(markdown)
      expect(structure.root_nodes.first.layer).to be true
    end

    it "parses roles" do
      structure = GroupStructure.parse(markdown)
      expect(structure.root_nodes.first.roles.length).to eq(1)
      expect(structure.root_nodes.first.roles.first.label).to eq("Role1")
    end

    it "parses permissions" do
      structure = GroupStructure.parse(markdown)
      expect(structure.root_nodes.first.roles.first.permissions).to eq([:read])
    end

    it "parses class names" do
      structure = GroupStructure.parse(markdown)
      expect(structure.root_nodes.first.roles.first.class_name).to eq("RoleClass")
    end
  end

  describe "#to_markdown" do
    let(:root_nodes) do
      [
        GroupStructure::GroupNode.new(
          klass: nil,
          label: "Layer1",
          layer: true,
          static: false,
          children: [],
          roles: [
            GroupStructure::RoleNode.new(
              klass: nil,
              label: "Role1",
              permissions: [:read],
              two_factor_authentication_enforced: false,
              class_name: "RoleClass"
            )
          ],
          depth: 0
        )
      ]
    end

    it "generates markdown without roles" do
      structure = GroupStructure.new(root_nodes)
      markdown = structure.to_markdown(include_roles: false)
      expect(markdown).to include("Layer1")
      expect(markdown).not_to include("Role1")
    end

    it "generates markdown with roles" do
      structure = GroupStructure.new(root_nodes)
      markdown = structure.to_markdown(include_roles: true)
      expect(markdown).to include("Layer1")
      expect(markdown).to include("Role1")
    end

    it "includes layer marker" do
      structure = GroupStructure.new(root_nodes)
      markdown = structure.to_markdown(include_roles: false)
      expect(markdown).to include("▲")
    end
  end

  describe "#to_ruby_classes" do
    let(:root_nodes) do
      [
        GroupStructure::GroupNode.new(
          klass: nil,
          label: "TestGroup",
          layer: false,
          static: false,
          children: [],
          roles: [],
          depth: 0
        )
      ]
    end

    it "generates Ruby class files" do
      structure = GroupStructure.new(root_nodes)
      classes = structure.to_ruby_classes
      expect(classes).to be_a(Hash)
      expect(classes.keys.first).to end_with(".rb")
    end
  end

  describe "#to_translations" do
    let(:root_nodes) do
      [
        GroupStructure::GroupNode.new(
          klass: nil,
          label: "TestGroup",
          layer: false,
          static: false,
          children: [],
          roles: [],
          depth: 0
        )
      ]
    end

    it "generates translation YAML" do
      structure = GroupStructure.new(root_nodes)
      translations = structure.to_translations
      expect(translations).to include("de:")
      expect(translations).to include("activerecord:")
    end
  end

  describe GroupStructure::GroupNode do
    let(:node) do
      GroupStructure::GroupNode.new(
        klass: nil,
        label: "TestGroup",
        layer: false,
        static: false,
        children: [],
        roles: [],
        depth: 0
      )
    end

    it "generates class name from label" do
      expect(node.class_name).to eq("TestGroup")
    end

    it "generates filename" do
      expect(node.filename).to eq("test_group.rb")
    end

    it "generates yaml key" do
      expect(node.yaml_key).to eq("test_group")
    end
  end

  describe GroupStructure::RoleNode do
    let(:role) do
      GroupStructure::RoleNode.new(
        klass: nil,
        label: "TestRole",
        permissions: [:read],
        two_factor_authentication_enforced: false,
        class_name: nil
      )
    end

    it "generates class name from label" do
      expect(role.class_name).to eq("TestRole")
    end

    it "generates filename" do
      expect(role.filename).to eq("test_role.rb")
    end
  end
end
