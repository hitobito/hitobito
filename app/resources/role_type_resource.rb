# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleTypeResource < ApplicationResource
  class Type
    attr_accessor :group_types

    delegate :label, :kind, :permissions, :visible_from_above, to: :@role_type

    def initialize(role_type)
      @role_type = role_type
      @group_types = []
    end

    def id
      @role_type.sti_name
    end
  end

  self.model = Type
  self.adapter = Graphiti::Adapters::Null
  self.default_page_size = max_page_size

  primary_endpoint "role_types", [:index]

  with_options writable: false, filterable: false, sortable: false do
    attribute :id, :string, sortable: true
    attribute :label, :string, sortable: true
    attribute :kind, :string
    attribute :permissions, :array_of_strings
    attribute :visible_from_above, :boolean
  end

  has_many :group_types do
    scope { resource.base_scope }

    assign_each do |role_type, group_types|
      group_types.select { |group_type| group_type.role_type_ids.include?(role_type.id) }
    end
  end

  sort :id do |scope, direction|
    sort_types(scope, direction, &:id)
  end

  sort :label do |scope, direction|
    sort_types(scope, direction, &:label)
  end

  stat :total do
    count { |scope, _attr| scope.size }
  end

  paginate do |scope, current_page, per_page, _context, offset|
    scope[(current_page - 1) * per_page + offset.to_i, per_page] || []
  end

  def base_scope
    ::Role.all_types.collect { |role_type| Type.new(role_type) }
  end

  private

  def sort_types(types, direction, &key)
    sorted = types.sort_by(&key)
    (direction == :desc) ? sorted.reverse : sorted
  end
end
