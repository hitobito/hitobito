# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupResource < ApplicationResource
  primary_endpoint 'groups', [:index, :show]

  with_options writable: false do
    attribute :name, :string
    attribute :short_name, :string
    attribute(:display_name, :string) { @object.display_name }
    attribute :description, :string
    attribute(:layer, :boolean) { @object.layer? }
    attribute :type, :string
    attribute :email, :string
    attribute :address, :string
    attribute :zip_code, :integer
    attribute :town, :string
    attribute :country, :string

    attribute :require_person_add_requests, :boolean
    attribute(:self_registration_url, :string) do
      next unless @object.self_registration_active?

      context.group_self_registration_url(group_id: @object.id)
    end

    attribute :archived_at, :datetime
    attribute :created_at, :datetime
    attribute :updated_at, :datetime
    attribute :deleted_at, :datetime

    extra_attribute :logo, :string do
      next unless @object.logo.attached?

      context.rails_storage_proxy_url(@object.logo.blob)
    end
  end

  belongs_to :contact, resource: PersonResource, writable: false, foreign_key: :contact_id
  belongs_to :creator, resource: PersonResource, writable: false, foreign_key: :creator_id
  belongs_to :updater, resource: PersonResource, writable: false, foreign_key: :updater_id
  belongs_to :deleter, resource: PersonResource, writable: false, foreign_key: :deleter_id

  belongs_to :parent, resource: GroupResource, writable: false, foreign_key: :parent_id
  belongs_to :layer_group, resource: GroupResource, writable: false, foreign_key: :layer_group_id do
    assign do |_groups, _layer_groups|
      # We use the accessor from `NestedSet#layer_group` and there is no setter method,
      # so we skip this.
      # Note: this might lead to a performance penalty.
    end
  end

  filter :with_deleted, :boolean, :single do
    eq do |scope, value|
      next scope unless value

      scope.unscope(where: :deleted_at)
    end
  end

  filter :with_archived, :boolean, :single do
    eq do |scope, value|
      next scope unless value

      scope.unscope(where: :archived_at)
    end
  end

  def authorize_create(model)
    # Writing groups is disabled for now
    raise CanCan::AccessDenied
  end

  def authorize_update(model)
    # Writing groups is disabled for now
    raise CanCan::AccessDenied
  end

  def index_ability
    JsonApi::GroupAbility.new(current_ability)
  end

  def base_scope
    Group.without_deleted.without_archived
  end
end
