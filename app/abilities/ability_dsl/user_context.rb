#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  class UserContext
    # rubocop:disable Style/MutableConstant These constants are meant to be extended
    GROUP_PERMISSIONS = [:layer_and_below_full, :layer_and_below_read, :layer_full, :layer_read,
      :group_and_below_full, :group_and_below_read, :group_full, :group_read,
      :finance, :see_invisible_from_above, :manual_deletion]

    LAYER_PERMISSIONS = [:layer_and_below_full, :layer_and_below_read, :layer_full, :layer_read,
      :finance, :see_invisible_from_above, :manual_deletion, :layer_and_below_finance]
    # rubocop:enable Style/MutableConstant

    attr_reader :user, :admin

    # All permissions symbols that the user actually has defined for all her roles.
    attr_reader :all_permissions

    def initialize(user)
      @user = user
      @all_permissions = user.roles.collect(&:permissions).flatten.uniq
      init_permission_lookup_tables
      @admin = all_permissions.include?(:admin)
    end

    # The ids of the groups where the given permission is defined.
    # Includes implied permission, i.e. when passing :group_read, the groups
    # where the user has :group_full are also returned.
    def permission_group_ids(permission)
      group_ids_with_permission(@permissions_group_ids, permission)
    end

    # The ids of the layer groups where the given layer permission is defined.
    # Includes implied permission, i.e. when passing :layer_read, the layer groups
    # where the user has :layer_full are also returned.
    def permission_layer_ids(permission)
      group_ids_with_permission(@permissions_layer_ids, permission)
    end

    def layer_ids(groups)
      groups.collect(&:layer_group_id).uniq
    end

    def participations
      @participations ||= user.event_participations.active.includes(:roles).to_a
    end

    def events_with_permission(permission)
      @events_with_permission ||= {}
      @events_with_permission[permission] ||= find_events_with_permission(permission)
    end

    def course_offerers
      @course_offerers ||= Group.course_offerers.pluck(:id)
    end

    private

    def init_permission_lookup_tables
      @permissions_group_ids = Hash.new { |hash, key| hash[key] = [] }
      @permissions_layer_ids = Hash.new { |hash, key| hash[key] = [] }

      permissions_groups = init_permission_groups
      init_permission_layers(permissions_groups)
      init_implicit_permission_groups
      init_derived_finance_permission
    end

    def init_derived_finance_permission
      user.groups_with_permission(:layer_and_below_finance).each do |group|
        layer_ids = group.layer_group.self_and_descendants.merge(Group.layers).pluck(:id)
        grant_groups_permissions(:finance, layer_ids)
        @permissions_layer_ids[:finance] = layer_ids
      end
    end

    def init_permission_groups
      permissions_groups = Hash.new { |hash, key| hash[key] = [] }
      GROUP_PERMISSIONS.each do |permission|
        groups = user.groups_with_permission(permission).to_a
        given = Role::PermissionImplications.invert[permission]
        groups += user.groups_with_permission(given).to_a if given

        grant_groups_permissions(permission, groups.map(&:id))
        permissions_groups[permission] |= groups
      end
      permissions_groups
    end

    def init_permission_layers(permissions_groups)
      LAYER_PERMISSIONS.each do |permission|
        @permissions_layer_ids[permission] = layer_ids(permissions_groups[permission])
      end
    end

    # rubocop:todo Metrics/MethodLength
    def init_implicit_permission_groups # rubocop:todo Metrics/CyclomaticComplexity
      Role::PermissionImplicationsForGroups.each do |trigger_permission, permission_configs|
        next unless all_permissions.include?(trigger_permission)

        # Find the layer groups associated with the user's trigger permission.
        layer_group_ids = user.groups_with_permission(trigger_permission).map(&:layer_group_id).uniq
        next if layer_group_ids.empty?

        permission_configs.each do |related_group_permission, related_group_classes|
          # rubocop:todo Layout/LineLength
          permissions_including_implicit = expand_permissions_with_implications(related_group_permission)
          # rubocop:enable Layout/LineLength
          target_group_ids = Group.where(
            type: Array(related_group_classes).map(&:sti_name),
            layer_group_id: layer_group_ids
          ).pluck(:id)

          unless target_group_ids.empty?
            grant_groups_permissions(permissions_including_implicit,
              target_group_ids)
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def grant_groups_permissions(permissions, group_ids)
      Array(permissions).each do |permission|
        @all_permissions |= [permission] if group_ids.any?
        @permissions_group_ids[permission] |= group_ids
      end
    end

    def expand_permissions_with_implications(*trigger_permissions)
      Role::PermissionImplications
        .each_with_object(Array(trigger_permissions)) do |(given, implicated), expanded_permissions|
        expanded_permissions.concat(Array(implicated)) if expanded_permissions.include?(given)
      end.uniq
    end

    def group_ids_with_permission(source, permission)
      if permission == :any
        source.values.flatten.uniq
      else
        source[permission]
      end
    end

    def find_events_with_permission(permission)
      participations.select { |p| p.roles.any? { |r| r.class.permissions.include?(permission) } }
        .collect(&:event_id)
    end
  end
end
