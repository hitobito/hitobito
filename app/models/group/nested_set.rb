# frozen_string_literal: true

#  Copyright (c) 2014, 2019 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Group::NestedSet
  extend ActiveSupport::Concern

  included do
    acts_as_nested_set dependent: :destroy

    before_save :store_new_display_name
    after_save :move_to_alphabetic_position
  end

  # The hierarchy from top to bottom of and including this group.
  def hierarchy
    @hierarchy ||= self_and_ancestors
  end

  # The layer of this group.
  def layer_group
    layer ? self : layer_hierarchy.last
  end

  # The layer hierarchy from top to bottom of this group.
  def layer_hierarchy
    hierarchy.select { |g| g.class.layer }
  end

  # The group hierarchy inside the layer of this group.
  def local_hierarchy
    hierarchy.select { |g| g.layer_group_id == layer_group_id }
  end

  # siblings with the same type
  def sister_groups
    self_and_sister_groups.where("id <> ?", id)
  end

  def self_and_sister_groups
    Group.without_deleted
         .where(parent_id: parent_id, type: type)
  end

  # siblings with the same type and all their descendant groups, including self
  def sister_groups_with_descendants
    Group.without_deleted
         .joins("LEFT JOIN #{Group.quoted_table_name} AS sister_groups " \
                "ON #{Group.quoted_table_name}.lft >= sister_groups.lft " \
                "AND #{Group.quoted_table_name}.lft < sister_groups.rgt")
         .where(sister_groups: {type: type, parent_id: parent_id})
  end

  # The layer hierarchy without the layer of this group.
  def upper_layer_hierarchy
    return [] unless parent

    if new_record?
      if layer?
        parent.layer_hierarchy
      else
        parent.layer_hierarchy - [parent.layer_group]
      end
    else
      layer_hierarchy - [layer_group]
    end
  end

  def use_hierarchy_from_parent(parent)
    parent_hierarchy = parent.is_a?(Group) ? parent.hierarchy : parent
    @hierarchy = parent_hierarchy + [self]
  end

  def groups_in_same_layer
    Group.where(layer_group_id: layer_group_id)
         .without_deleted
         .order(:lft)
  end

  def has_sublayers? # rubocop:disable Naming/PredicateName
    children.any? { |child| child.layer? }
  end

  def no_touch_on_move
    true
  end

  private

  def store_new_display_name
    @move_to_new_name = name_changed? || short_name_changed? ? display_name : false
    true # force callback to return true
  end

  def move_to_alphabetic_position
    return unless move_required?

    left_neighbor = find_left_neighbor(parent, :display_name_downcase, true)
    if left_neighbor
      move_to_right_of_if_change(left_neighbor)
    else
      move_to_most_left_if_change
    end
  end

  def move_required?
    (@move_to_new_parent_id != false || @move_to_new_name != false) &&
      parent_id &&
      parent.children.count > 1
  end

  def move_to_right_of_if_change(node)
    if node.display_name.downcase != display_name.downcase && node.rgt != lft - 1
      move_to_right_of(node)
    end
  end

  def move_to_most_left_if_change
    first = parent.children[0]
    move_to_left_of(first) unless first == self
  end
end
