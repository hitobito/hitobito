# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleTypeResource < ApplicationResource
  include TypeResource

  class Type < TypeResource::Type
    attr_accessor :group_types

    delegate :label, :kind, :permissions, :visible_from_above, to: :@type

    def initialize(role_type)
      super
      @group_types = []
    end

    def group_type_ids
      @group_type_ids ||= ::Group.all_types
        .select { |group_type| group_type.role_types.include?(@type) }
        .collect(&:sti_name)
    end
  end

  self.model = Type

  primary_endpoint "role_types", [:index]

  with_options writable: false, filterable: false, sortable: false do
    attribute :kind, :string
    attribute :permissions, :array_of_strings
    attribute :visible_from_above, :boolean
  end

  sideload_types :group_types, ids: :group_type_ids

  def base_scope
    ::Role.all_types.collect { |role_type| Type.new(role_type) }
  end
end
