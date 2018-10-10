# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  class UserContext

    GROUP_PERMISSIONS = [:layer_and_below_full, :layer_and_below_read, :layer_full, :layer_read,
                         :group_and_below_full, :group_and_below_read, :group_full, :group_read,
                         :finance ]

    LAYER_PERMISSIONS = [:layer_and_below_full, :layer_and_below_read, :layer_full, :layer_read, 
                         :finance]

    attr_reader :user, :admin

    def initialize(user)
      @user = user
      init_groups
    end

    # All permissions symbols that the user actually has defined for all her roles.
    def all_permissions
      @all_permissions ||= begin
        permissions = user.roles.collect(&:permissions).flatten.uniq
        Role::PermissionImplications.each do |given, implicated|
          if permissions.include?(given) && !permissions.include?(implicated)
            permissions << implicated
          end
        end
        permissions
      end
    end

    # The ids of the groups where the given permission is defined.
    # Includes implied permission, i.e. when passing :group_read, the groups
    # where the user has :group_full are also returned.
    def permission_group_ids(permission)
      group_ids_with_permission(@permission_group_ids, permission)
    end

    # The ids of the layer groups where the given layer permission is defined.
    # Includes implied permission, i.e. when passing :layer_read, the layer groups
    # where the user has :layer_full are also returned.
    def permission_layer_ids(permission)
      group_ids_with_permission(@permission_layer_ids, permission)
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

    private

    def init_groups
      @admin = user.groups_with_permission(:admin).present?

      init_permission_groups
      init_permission_layers

      collect_group_ids!
    end

    def init_permission_groups
      @permission_group_ids = GROUP_PERMISSIONS.each_with_object({}) do |permission, hash|
        groups = user.groups_with_permission(permission).to_a
        given = Role::PermissionImplications.invert[permission]
        groups += user.groups_with_permission(given).to_a if given
        hash[permission] = groups
      end
    end

    def init_permission_layers
      @permission_layer_ids = LAYER_PERMISSIONS.each_with_object({}) do |permission, hash|
        hash[permission] = layer_ids(@permission_group_ids[permission])
      end
    end

    def collect_group_ids!
      @permission_group_ids.values.each { |groups| groups.collect!(&:id) }
    end

    def group_ids_with_permission(source, permission)
      if permission == :any
        source.values.flatten.uniq
      else
        source[permission]
      end
    end

    def find_events_with_permission(permission)
      participations.select { |p| p.roles.any? { |r| r.class.permissions.include?(permission) } }.
                     collect(&:event_id)
    end

  end
end
