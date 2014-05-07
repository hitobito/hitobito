# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Group::Types
  extend ActiveSupport::Concern

  included do
    class_attribute :layer, :role_types, :possible_children, :default_children, :event_types

    # Whether this group type builds a layer or is a regular group.
    # Layers influence some permissions.
    self.layer = false
    # List of the role types that are available for this group type.
    self.role_types = []
    # Child group types that may be created for this group type.
    self.possible_children = []
    # Child groups that are automatically created with a group of this type.
    self.default_children = []
    # All possible Event types that may be created for this group
    self.event_types = [Event]


    after_create :set_layer_group_id
    after_update :set_layer_group_id
    after_create :create_default_children

    validate :assert_type_is_allowed_for_parent, on: :create
  end

  private

  def create_default_children
    default_children.each do |group_type|
      child = group_type.new(name: group_type.label)
      child.parent = self
      child.save!
    end
  end

  def assert_type_is_allowed_for_parent
    if type && parent && !parent.possible_children.collect(&:sti_name).include?(type)
      errors.add(:type, :type_not_allowed)
    end
  end

  def set_layer_group_id
    layer_id = self.class.layer ? id : parent.layer_group_id
    unless layer_id == layer_group_id
      update_column(:layer_group_id, layer_id)
    end
  end

  module ClassMethods

    # DSL method to define children
    def children(*group_types)
      self.possible_children = group_types + possible_children
    end

    # DSL method to define roles
    def roles(*types)
      self.role_types = types + role_types
    end

    # All group types available in the application
    def all_types
      @@all_types ||= tsort(collect_types([], root_types))
    end

    # All root group types in the application.
    # Used as a DSL method to define root types if arguments are given.
    def root_types(*types)
      @@root_types ||= []
      if types.present?
        reset_types!
        @@root_types += types
      else
        @@root_types.clone
      end
    end

    # Helper method to clear the cached group and role types.
    def reset_types!
      @@root_types = []
      @@all_types = nil
      Role.reset_types!
    end

    # All the group types underneath the current group type.
    def child_types
      tsort(collect_types([], [self]))
    end

    # All group types the may provide courses
    def course_types
      @@course_types ||=
        all_types.select do |type|
          type.event_types.include?(Event::Course)
        end
    end

    # All groups that may offer courses
    def course_offerers
      where(type: course_types.map(&:sti_name)).
      order(:parent_id, :name)
    end

    # Return the group type with the given sti_name or raise an exception if not found
    def find_group_type!(sti_name)
      type = all_types.detect { |t| t.sti_name == sti_name }
      fail ActiveRecord::RecordNotFound, "No group '#{sti_name}' found" if type.nil?
      type
    end

    # Return the role type with the given sti_name or raise an exception if not found
    def find_role_type!(sti_name)
      type = role_types.detect { |t| t.sti_name == sti_name }
      fail ActiveRecord::RecordNotFound, "No role '#{sti_name}' found" if type.nil?
      type
    end

    def label
      model_name.human
    end

    def label_plural
      model_name.human(count: 2)
    end

    private

    def collect_types(all, types)
      types.each do |type|
        unless all.include?(type)
          all << type
          collect_types(all, type.possible_children)
        end
      end

      all
    end

    def tsort(types)
      TypeSorter.new(types).sort
    end

  end

  # Sorts a list of types according to the defined hierarchy
  class TypeSorter
    include TSort

    def initialize(types)
      @types = types
    end

    def tsort_each_node(&block)
      @types.each(&block)
    end

    def tsort_each_child(type, &block)
      type.possible_children.reverse.each(&block)
    end

    def sort
      tsort.reverse
    end
  end
end
