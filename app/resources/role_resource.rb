# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleResource < ApplicationResource
  primary_endpoint "roles", [:index, :create, :show, :update, :destroy]

  with_options writable: false do
    attribute :created_at, :datetime
    attribute :updated_at, :datetime
    attribute :deleted_at, :datetime
  end

  attribute :person_id, :integer
  attribute :group_id, :integer
  attribute :type, :string
  attribute :label, :string

  before_save :raise_when_changing_readonly_attr, only: [:update]

  belongs_to :person, writable: false
  belongs_to :group, writable: false

  has_one :layer_group, resource: GroupResource, writable: false do
    params do |hash, roles|
      hash[:filter] = {id: roles.flat_map { |role| role.group.layer_group_id }}
    end
    assign do |_roles, _layer_groups|
      # We use the accessor from `NestedSet#layer_group` and there is no setter method,
      # so we skip this.
      # Note: this might lead to a performance penalty.
    end
  end

  def index_ability
    JsonApi::RoleAbility.new(current_ability)
  end

  private

  def raise_when_changing_readonly_attr(model)
    errors = Graphiti::Util::SimpleErrors.new({})
    [:group_id, :person_id, :type].each do |attr|
      next unless model.changes.key?(attr.to_s)
      errors.add(attr, :unwritable_attribute, message: "cannot be written")
    end
    raise Graphiti::Errors::InvalidRequest, errors if errors.any?
  end
end
