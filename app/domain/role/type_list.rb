#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Role
  # Composes a nested hash of layer types, group types and role types.
  class TypeList

    attr_reader :root, :role_types

    def initialize(root_type)
      @root = root_type
      @excluded = [FutureRole]
      compose
    end

    def each(&block)
      @role_types.each(&block)
    end

    def flatten
      @role_types.flat_map do |layer, groups|
        groups.flat_map do |group, roles|
          next roles unless block_given?

          roles.map { |role| yield role, group, layer }
        end
      end
    end

    private

    # hash with the form {layer: {group: [roles]}}
    def compose
      @global_group_types = find_global_group_types(root, root)
      @global_role_types = find_global_role_types(root).uniq
      @role_types = Hash.new { |h0, k0| h0[k0] = Hash.new { |h1, k1| h1[k1] = [] } }

      # layers
      unless @global_group_types.include?(root)
        compose_role_list_by_layer(root)
      end

      compose_global_role_list
    end

    def compose_role_list_by_layer(layer, group = layer, seen_groups = [])
      seen_groups << group
      set_role_types(layer, group)
      group.possible_children.each do |child|
        if seen_groups.include?(child)
          # set again to move to the end of the list
          set_role_types(layer, child) unless child.layer
        else
          if child.layer
            compose_role_list_by_layer(child, child, seen_groups)
          elsif !@global_group_types.include?(child)
            compose_role_list_by_layer(layer, child, seen_groups)
          end
        end
      end
    end

    def set_role_types(layer, group)
      layer_types = @role_types[layer.label]
      types = layer_types.delete(group.label).presence || local_role_types(group)
      layer_types[group.label] = types if types.present?
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

    # groups appearing in the possible (sub) children of more than one layer
    def find_global_group_types(group, layer, _group_layers = {})
      group_layers = {}
      find_group_layers(group, layer, group_layers)
      group_types = group_layers.select { |_, layers| layers.uniq.size > 1 }.keys
      group_types.flat_map { |type| [type] + type.child_types  }.uniq
    end

    def find_group_layers(group, layer, group_layers)
      group_layers[group] = [layer]
      group.possible_children.each do |child|
        if group_layers.key?(child)
          group_layers[child] << layer unless child.layer
        else
          find_group_layers(child, child.layer ? child : layer, group_layers)
        end
      end
    end

    # role types appearing in more than one group
    def find_global_role_types(group)
      global = []
      seen_types = []
      group.child_types.each do |child|
        child.role_types.each do |role|
          next if @excluded.include?(role)

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
      group.role_types.select do |r|
        !r.restricted? && local_role_type?(r) && @excluded.exclude?(r)
      end
    end

    def local_role_type?(type)
      !@global_role_types.include?(type)
    end

  end
end
