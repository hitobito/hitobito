# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupTypeResource < ApplicationResource
  class Type
    attr_accessor :role_types, :possible_children

    delegate :label, :label_plural, :layer, to: :@group_type

    def initialize(group_type)
      @group_type = group_type
      @role_types = []
      @possible_children = []
    end

    def id
      @group_type.sti_name
    end

    def role_type_ids
      @role_type_ids ||= @group_type.role_types.collect(&:sti_name)
    end

    def possible_children_ids
      @possible_children_ids ||= @group_type.possible_children.collect(&:sti_name)
    end
  end

  self.model = Type
  self.adapter = Graphiti::Adapters::Null
  self.default_page_size = max_page_size

  primary_endpoint "group_types", [:index]

  with_options writable: false, filterable: false, sortable: false do
    attribute :id, :string, sortable: true
    attribute :label, :string, sortable: true
    attribute :label_plural, :string
    attribute :layer, :boolean
  end

  has_many :role_types do
    scope { resource.base_scope }

    assign_each do |group_type, role_types|
      role_types.select { |role_type| group_type.role_type_ids.include?(role_type.id) }
    end
  end

  has_many :possible_children, resource: GroupTypeResource do
    scope { resource.base_scope }

    assign_each do |group_type, group_types|
      group_types.select { |child| group_type.possible_children_ids.include?(child.id) }
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
    ::Group.all_types.collect { |group_type| Type.new(group_type) }
  end

  private

  def sort_types(types, direction, &key)
    sorted = types.sort_by(&key)
    (direction == :desc) ? sorted.reverse : sorted
  end
end
