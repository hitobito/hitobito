# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceLists
  class Receivers
    attr_reader :role_types, :layer, :layer_group_ids

    def initialize(config, layer_group_ids = nil)
      @layer = config.layer
      @role_types = config.roles
      @layer_group_ids = layer_group_ids
    end

    def build
      roles.map do |role|
        Receiver.new(id: role.person_id, layer_group_id: role.group.layer_group_id)
      end
    end

    def addressable_layer_group_ids
      @addressable_layer_group_ids ||= roles.map { |r| r.group.layer_group_id }
    end

    def roles
      @roles ||= roles_scope.where(type: role_types)
        .order(:layer_group_id, Arel.sql(order_by_roles_statement))
        .select("DISTINCT ON (groups.layer_group_id) roles.*, groups.layer_group_id")
    end

    def layers_with_missing_receiver
      layers.where.not(id: roles.map { |r| r.group.layer_group_id })
    end

    private

    def layers = Group.where(type: layer)

    def roles_scope
      Role.joins(:group).then do |scope|
        next scope unless layer_group_ids
        scope.where(groups: {layer_group_id: layer_group_ids})
      end
    end

    def order_by_roles_statement
      role_types.map.with_index do |role, index|
        " WHEN roles.type = '#{role}' THEN #{index}"
      end.prepend("CASE").append("END").join("\n")
    end
  end
end
