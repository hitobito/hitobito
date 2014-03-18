# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Role
  class TypeList

    attr_reader :root

    def initialize(root_type)
      @root = root_type
      compose
    end

    def each(&block)
      @role_types.each(&block)
    end

    private

    # hash with the form {layer: {group: [roles]}}
    def compose
      @global_group_types = find_global_group_types([], root).uniq
      @global_role_types = find_global_role_types(root).uniq
      @role_types = Hash.new { |h0, k0| h0[k0] = Hash.new { |h1, k1| h1[k1] = [] } }

      # layers
      unless @global_group_types.include?(root)
        compose_role_list_by_layer(root)
      end

      compose_global_role_list
    end

    def compose_role_list_by_layer(layer, seen_layers = [])
      seen_layers << layer
      set_role_types(layer, layer)
      layer.possible_children.each do |child|
        if child.layer
          compose_role_list_by_layer(child) unless seen_layers.include?(child)
        elsif !@global_group_types.include?(child)
          set_role_types(layer, child)
        end
      end
    end

    def set_role_types(layer, group)
      types = local_role_types(group)
      @role_types[layer.label][group.label] = types if types.present?
    end

    def compose_global_role_list
       # global groups
      @global_group_types.each do |group|
        types = local_role_types(group)
        @role_types['Global'][group.label] = types if types.present?
      end

      # global roles
      @role_types['Global']['Global'] = @global_role_types if @global_role_types.present?
    end

    # groups appearing in the possible children of more than one group
    def find_global_group_types(seen_types, group, global = [])
      group.possible_children.each do |child|
        process_gobal_group(seen_types, group, child, global)
      end
      global
    end

    def process_gobal_group(seen_types, group, child, global)
      if seen_types.include?(child)
        unless child.layer || child == group
          global << child
        end
      else
        seen_types << child
        find_global_group_types(seen_types, child, global)
      end
    end

    # role types appearing in more than one group
    def find_global_role_types(group)
      global = []
      seen_types = []
      group.child_types.each do |child|
        child.role_types.each do |role|
          process_global_role(seen_types, role, global)
        end
      end
      global
    end

    def process_global_role(seen_types, role, global)
      if seen_types.include?(role)
        global << role
      end
      seen_types << role
    end

    def local_role_types(group)
      group.role_types.select { |r| !r.restricted? && local_role_type?(r) }
    end

    def local_role_type?(type)
      !@global_role_types.include?(type)
    end

  end
end
