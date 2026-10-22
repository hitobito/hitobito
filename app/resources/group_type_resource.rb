# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupTypeResource < ApplicationResource
  include TypeResource

  class Type < TypeResource::Type
    attr_accessor :role_types, :possible_children

    delegate :label, :label_plural, :layer, to: :@type

    def initialize(group_type)
      super
      @role_types = []
      @possible_children = []
    end

    def role_type_ids
      @role_type_ids ||= @type.role_types.collect(&:sti_name)
    end

    def possible_children_ids
      @possible_children_ids ||= @type.possible_children.collect(&:sti_name)
    end
  end

  self.model = Type

  primary_endpoint "group_types", [:index]

  with_options writable: false, filterable: false, sortable: false do
    attribute :label_plural, :string
    attribute :layer, :boolean
  end

  sideload_types :role_types, ids: :role_type_ids
  sideload_types :possible_children, ids: :possible_children_ids, resource: GroupTypeResource

  def base_scope
    ::Group.all_types.collect { |group_type| Type.new(group_type) }
  end
end
