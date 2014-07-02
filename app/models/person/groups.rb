# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::Groups
  extend ActiveSupport::Concern


  # Uniq set of all group ids in hierarchy.
  def groups_hierarchy_ids
    @hierarchy_ids ||= groups.collect(&:hierarchy).flatten.collect(&:id).uniq
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
    roles.to_a.reject { |r| r.class.restricted? }.collect(&:group)
  end

  # All groups where this person has the given permission(s).
  def groups_with_permission(permission)
    @groups_with_permission ||= {}
    @groups_with_permission[permission] ||= begin
      roles.to_a.select { |r| r.class.permissions.include?(permission) }.collect(&:group).uniq
    end
    @groups_with_permission[permission].dup
  end

  # Does this person have the given permission in any group.
  def permission?(permission)
    roles.any? { |r| r.class.permissions.include?(permission) }
  end

  # All groups where this person has a role that is visible from above.
  def groups_where_visible_from_above
    roles.select { |r| r.class.visible_from_above }.collect(&:group).uniq
  end

  # All above and actual groups where this person is visible from.
  def above_groups_where_visible_from
    groups_where_visible_from_above.collect(&:hierarchy).flatten.uniq
  end


  module ClassMethods
    # Scope listing only people that have roles that are visible from above.
    # If group is given, only visible roles from this group are considered.
    def visible_from_above(group = nil)
      role_types = group ? group.role_types.select(&:visible_from_above) : Role.visible_types
      # use string query to only get these roles (hash query would be merged).
      where('roles.type IN (?)', role_types.collect(&:sti_name))
    end

    # Scope listing all people with a role in the given layer.
    def in_layer(*groups)
      joins(roles: :group).
      where(roles: { deleted_at: nil },
            groups: { layer_group_id: groups.collect(&:layer_group_id) }).
      uniq
    end

    # Scope listing all people with a role in or below the given group.
    def in_or_below(group)
      joins(roles: :group).
      where(roles: { deleted_at: nil }).
      where('groups.lft >= :lft AND groups.rgt <= :rgt', lft: group.lft, rgt: group.rgt).
      uniq
    end

    # Load people with member roles.
    def members
      member_types = Role.all_types.select(&:member?).collect(&:sti_name)
      where(roles: { type: member_types })
    end

    # Order people by the order role types are listed in their group types.
    def order_by_role
      order(order_by_role_statement)
    end

    def order_by_role_statement
      statement = 'CASE roles.type '
      Role.all_types.each_with_index do |t, i|
        statement << "WHEN '#{t.sti_name}' THEN #{i} "
      end
      statement << 'END'
    end
  end
end
