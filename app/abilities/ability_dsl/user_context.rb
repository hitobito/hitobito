# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  class UserContext

    attr_reader :user,
                :groups_group_full,
                :groups_group_read,
                :groups_layer_full,
                :groups_layer_read,
                :groups_layer_and_below_full,
                :groups_layer_and_below_read,
                :layers_read,
                :layers_full,
                :layers_and_below_read,
                :layers_and_below_full,
                :admin

    def initialize(user)
      @user = user
      init_groups
    end

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

    def layer_ids(groups)
      groups.collect(&:layer_group_id).uniq
    end

    def participations
      @participations ||= user.event_participations.includes(:roles).to_a
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
      @groups_group_full = user.groups_with_permission(:group_full).to_a
      @groups_group_read = user.groups_with_permission(:group_read).to_a + @groups_group_full
      @groups_layer_full = user.groups_with_permission(:layer_full).to_a
      @groups_layer_read = user.groups_with_permission(:layer_read).to_a +
                                     @groups_layer_full
      @groups_layer_and_below_full = user.groups_with_permission(:layer_and_below_full).to_a
      @groups_layer_and_below_read = user.groups_with_permission(:layer_and_below_read).to_a +
                                     @groups_layer_and_below_full
    end

    def init_permission_layers
      @layers_full = layer_ids(@groups_layer_full)
      @layers_read = layer_ids(@groups_layer_read)

      @layers_and_below_full = layer_ids(@groups_layer_and_below_full)
      @layers_and_below_read = layer_ids(@groups_layer_and_below_read)
    end

    def collect_group_ids!
      [@groups_group_full,
       @groups_group_read,
       @groups_layer_full,
       @groups_layer_read,
       @groups_layer_and_below_full,
       @groups_layer_and_below_read].each do |list|
        list.collect!(&:id)
      end
    end

    def find_events_with_permission(permission)
      participations.select { |p| p.roles.any? { |r| r.class.permissions.include?(permission) } }.
                     collect(&:event_id)
    end

  end
end
