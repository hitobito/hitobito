# frozen_string_literal: true

#  Copyright (c) 2012-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Common Base Class for fetching entities belonging to a group.
class GroupBasedFetchables
  include CanCan::Ability

  class_attribute :same_group_permissions, :above_group_permissions,
    :same_layer_permissions, :above_layer_permissions
  self.same_group_permissions = []
  self.above_group_permissions = []
  self.same_layer_permissions = []
  self.above_layer_permissions = []

  attr_reader :user_context

  delegate :user, to: :user_context

  def initialize(user)
    @user_context = AbilityDsl::UserContext.new(user)
  end

  private

  def append_group_conditions(condition)
    in_same_group_condition(condition)
    in_above_group_condition(condition)
    in_same_layer_condition(condition)
  end

  def in_same_group_condition(condition)
    if group_ids_same_group.present?
      condition.or("#{Group.quoted_table_name}.id IN (?)", group_ids_same_group)
    end
  end

  def in_above_group_condition(condition)
    groups_above_group.each do |group|
      condition.or("#{Group.quoted_table_name}.lft >= ? AND #{Group.quoted_table_name}.rgt <= ? " \
                   "AND #{Group.quoted_table_name}.layer_group_id = ?",
        group.lft, group.rgt,
        group.layer_group_id)
    end
  end

  def in_same_layer_condition(condition)
    if layer_group_ids_same_layer.present?
      condition.or("#{Group.quoted_table_name}.layer_group_id IN (?)",
        layer_group_ids_same_layer)
    end
  end

  def groups_same_group
    @groups_same_group ||= Group.where(id: group_ids_same_group)
  end

  def groups_above_group
    @groups_above_group ||= Group.where(id: group_ids_above_group)
  end

  def layer_groups_same_layer
    @layer_groups_same_layer ||= Group.where(id: layer_group_ids_same_layer)
  end

  def layer_groups_above
    @layer_groups_above ||= Group.where(id: layer_group_ids_above)
  end

  def group_ids_same_group
    @group_ids_same_group ||= group_ids_with_permissions(*same_group_permissions)
  end

  def group_ids_above_group
    @group_ids_above_group ||= group_ids_with_permissions(*above_group_permissions)
  end

  def layer_group_ids_same_layer
    @layer_group_ids_same_layer ||= layer_group_ids_with_permissions(*same_layer_permissions)
  end

  def layer_group_ids_above
    @layer_group_ids_above ||= layer_group_ids_with_permissions(*above_layer_permissions)
  end

  def layer_group_ids_with_permissions(*permissions)
    permissions.collect { |p| user_context.permission_layer_ids(p) }
      .flatten
      .uniq
  end

  def group_ids_with_permissions(*permissions)
    permissions.collect { |p| user_context.permission_group_ids(p) }
      .flatten
      .uniq
  end
end
