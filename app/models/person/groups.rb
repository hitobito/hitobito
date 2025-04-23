# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::Groups
  extend ActiveSupport::Concern

  def readable_group_ids
    @readable_group_ids ||= Role.where(person_id: id)
  end

  # Uniq set of all group ids in hierarchy.
  def groups_hierarchy_ids
    @groups_hierarchy_ids ||= groups.collect(&:hierarchy).flatten.collect(&:id).uniq
  end

  # All layers this person belongs to.
  def layer_groups
    groups.collect(&:layer_group).uniq
  end

  # All layer ids this person belongs to.
  def layer_group_ids
    groups.collect(&:layer_group_id).uniq
  end

  # All groups where this person has a non-restricted role.
  def non_restricted_groups
    roles_with_groups.to_a.reject { |r| r.class.restricted? }.collect(&:group).uniq
  end

  # All groups where this person has the given permission.
  def groups_with_permission(permission)
    @groups_with_permission ||= {}
    @groups_with_permission[permission] ||=
      roles_with_groups.to_a
        .select { |r| r.permissions.include?(permission) }
        .collect(&:group)
        .uniq
    @groups_with_permission[permission].dup
  end

  # Does this person have the given permission in any group.
  def permission?(permission)
    roles.any? { |r| r.class.permissions.include?(permission) }
  end

  # All groups where this person has a role that is visible from above.
  def groups_where_visible_from_above(roles = roles_with_groups)
    roles.select { |r| r.class.visible_from_above }.collect(&:group).uniq
  end

  # All above and actual groups where this person is visible from.
  def above_groups_where_visible_from(groups = groups_where_visible_from_above)
    groups.collect(&:hierarchy).flatten.uniq
  end

  def last_non_restricted_role
    return nil if roles.exists?

    restricted = Role.all_types.select(&:restricted?).collect(&:sti_name)
    roles.with_inactive.where.not(type: restricted).order(end_on: :desc).first
  end

  private

  # Helper method to access the roles association,
  # asserting that groups have been preloaded together with roles.
  def roles_with_groups
    Person::PreloadGroups.for([self]) unless roles.loaded?
    roles
  end

  module ClassMethods
    # Scope listing only people that have roles that are visible from above.
    # If group is given, only visible roles from this group are considered.
    def visible_from_above(group = nil)
      role_types = group ? group.role_types.select(&:visible_from_above) : Role.visible_types
      # use string query to only get these roles (hash query would be merged).
      where(roles: {type: role_types.collect(&:sti_name)})
    end

    # Scope listing all people with a role in the given group.
    def in_group(group, join = {roles: :group})
      joins(join).where(groups: {id: group.id})
    end

    # Scope listing all people with a role in the given layer.
    def in_layer(*groups)
      joins(groups.extract_options![:join] || {roles: :group})
        .where(groups: {layer_group_id: groups.collect(&:layer_group_id), deleted_at: nil})
        .distinct
    end

    # Scope listing all people with a role in or below the given group.
    def in_or_below(group, join = {roles: :group})
      joins(join)
        .where(groups: {deleted_at: nil})
        .where("#{Group.quoted_table_name}.lft >= :lft AND #{Group.quoted_table_name}.rgt <= :rgt",
          lft: group.lft, rgt: group.rgt)
        .distinct
    end

    # Load people with member roles.
    def members(group = nil)
      types = group ? group.role_types : Role.all_types
      member_types = types.select(&:member?).collect(&:sti_name)
      where(roles: {type: member_types})
    end

    # Order people by the order role types are listed in their group types.
    def order_by_role
      subquery = joins(:roles)
        .joins("INNER JOIN role_type_orders ON role_type_orders.name = roles.type")
        .reselect(:order_weight, "people.*")
        .distinct_on(:id)
      Person.select("people.*").from(subquery, "people").unscope(:where).order(:order_weight)
    end
  end
end
