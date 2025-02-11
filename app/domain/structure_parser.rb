# frozen_string_literal: true

#  Copyright (c) 2023-2023, Jungschar EMK. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "English"
require "pathname"
require "yaml"
require "active_support/inflector"
require "set"

# parses a structure as output by rake app:hitobito:roles
class StructureParser
  attr_reader :result, :errors

  def initialize(structure, common_indent: 4, shiftwidth: 2, list_marker: "*", allowed_permissions: [])
    # data
    @structure = structure

    # config
    @common_indent = " " * common_indent.to_i
    @shiftwidth = " " * shiftwidth.to_i
    @list_marker = list_marker

    # state init
    @current_layer = nil
    @current_group = nil
    @result = {}
    @permissions = Set.new
    @allowed_permissions = Set.new(allowed_permissions)
    @errors = []
  end

  module Structure
    class Group
      attr_reader :name, :layer, :roles

      def initialize(name, layer = nil)
        @name = name
        @layer = layer

        @roles = []
      end

      def inspect
        to_s.inspect
      end

      def to_s
        "Group #{@name} with #{@roles.count} role(s)"
      end

      def to_group
        StructureParser::Group.new(@name, @layer)
      end
    end

    class Layer < Group
      attr_reader :children

      def initialize(name)
        super
        @children = []
      end

      def to_s
        "Layer #{@name} with #{@children.count} subgroup(s)"
      end
    end
  end

  class Group
    attr_reader :children, :roles
    attr_accessor :layer_group, :layer_name, :name

    def initialize(name, layer = nil)
      @name = name
      @layer = layer

      @layer_group = false
      @children = []
      @roles = []
    end

    def inspect
      to_s.inspect
    end

    def to_s
      type = @layer_group ? "LayerGroup" : "Group"
      "#{type} #{@name} with #{@children.count} subgroup(s) and #{@roles.count} role(s)"
    end

    def class_name
      @class_name ||= @name.encode(
        "ASCII", "UTF-8",
        fallback: {"ä" => "ae", "ü" => "ue", "ö" => "oe"}
      )
    end

    def child_class_names
      @children.map(&:full_class_name)
    end

    def full_class_name
      [@layer&.name, class_name].compact.join
    end

    def role_class_names
      @roles.map(&:class_name)
    end

    def yaml_key
      @yaml_key ||= ActiveSupport::Inflector.underscore(class_name)
    end
  end

  class Role
    attr_accessor :group, :name

    def initialize(name, permissions)
      @name = name
      @permissions = parse_permissions(permissions)
    end

    def parse_permissions(permissions)
      instance_eval(permissions)
    end

    def permissions
      @permissions.map(&:inspect).join(", ")
    end

    def permissions?
      @permissions.any?
    end

    def inspect
      to_s.inspect
    end

    def to_s
      group_text = "in group #{group.name}" if group

      "Role #{@name} with #{@permissions.inspect} #{group_text}".strip
    end

    def class_name
      @class_name ||= @name.delete_suffix("/-in")
        .delete_suffix("/-r")
        .encode("ASCII", "UTF-8", fallback: {
          "ä" => "ae",
          "ü" => "ue",
          "ö" => "oe"
        })
    end

    def name_for_translation
      @name.delete_prefix(group&.layer_name.to_s)
    end

    def yaml_key
      "#{group.yaml_key}/#{ActiveSupport::Inflector.underscore(class_name)}"
    end
  end

  def valid?
    if @result.empty?
      @errors << "Nothing has been detected. Empty or malformed input file?"
    end
    if @permissions.empty?
      @errors << "No permissions have been granted. This is impractical."
    end
    unless @permissions.subset?(@allowed_permissions)
      @errors << "Unknown permissions detected. Typos?"
    end

    @errors.empty?
  end

  def parse
    first_pass
    second_pass
  end

  def first_pass # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize
    @structure.lines.each do |line|
      case line.delete_prefix(@common_indent).chomp
      when /^#{Regexp.escape(@list_marker)} (.*?)(\s+<\s+(.*))?$/ # layer
        name = Regexp.last_match(1)
        super_layer = find_layer_by_name(Regexp.last_match(3))
        layer = Structure::Layer.new(name)

        super_layer.children << layer unless super_layer.nil?
        @current_layer = layer
        @current_group = layer
        @result[layer] ||= {}
      when /^#{@shiftwidth}#{Regexp.escape(@list_marker)} (.*)$/ # group
        name = Regexp.last_match(1)
        group = Structure::Group.new(name, @current_layer)

        @current_layer.children << group
        @current_group = group
        @result[@current_layer][group] ||= []
      when /^#{@shiftwidth * 2}#{Regexp.escape(@list_marker)} (.*):\s+(\[.*\])$/
        match = Regexp.last_match
        role = Role.new(match[1], match[2])

        @current_group.roles << role
        @result[@current_layer][@current_group] << role
      end
    end
  end

  def second_pass # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize
    first_pass = @result.dup

    @result = []
    first_pass.each do |layer, groups|
      groups.each do |group, roles|
        new_group = Group.new(group.name)
        if group.name == layer.name
          new_group.layer_group = true
          layer.children
            .reject { |child| child.name == group.name }
            .each { |child| new_group.children << child.to_group }
        else
          new_group.name = layer.name + group.name
        end

        roles.each do |role|
          role.group = new_group
          new_group.roles << role

          @permissions.merge(
            role.permissions.split(",").map { _1.strip.delete_prefix(":").to_sym }
          )
        end

        @result << new_group
      end
    end
  end

  def output_groups
    @result.map { |group| group_template(group) }
  end

  def output_translations
    groups, roles = @result.reduce([[], []]) do |memos, group|
      groups, roles = memos

      groups << group
      group.roles.each do |role|
        roles << role
      end

      [groups, roles]
    end

    translations(groups, roles)
  end

  private

  def find_layer_by_name(name)
    return nil if name.nil?

    @result.keys.find { |layer| layer.name == name }
  end

  def group_template(group)
    <<~CODE
      class Group::#{group.class_name} < ::Group
        #{"self.layer = true" if group.layer_group}
        #{"children " if group.children.any?}#{group.child_class_names.join(",\n")}

        ### ROLES

      #{group.roles.map { |role| role_template(role) }.join("\n\n")}

        roles #{group.role_class_names.join(", ")}
      end
    CODE
  end

  def role_template(role)
    <<-CODE
  class #{role.class_name} < ::Role
    self.permissions = [#{role.permissions}]
  end
    CODE
  end

  def translations(groups, roles)
    <<~CODE
      de:
        activerecord:
          models:

            ### GROUPS

      #{groups.map { |group| group_translations(group) }.join("\n")}

            ### ROLES

      #{roles.map { |role| role_translations(role) }.join("\n")}
    CODE
  end

  def group_translations(group)
    <<-YAML
      group/#{group.yaml_key}:
        one: #{group.name}
        other: TODO
    YAML
  end

  def role_translations(role)
    <<-YAML
      group/#{role.yaml_key}:
        one: #{role.name_for_translation}
        description: TODO
    YAML
  end
end
