# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationResource < Graphiti::Resource
  # Must be set when no corresponding model/query
  self.abstract_class = true

  # Subclasses can override if needed
  self.adapter = Graphiti::Adapters::ActiveRecord

  # Default attribute flags:
  # attribute :title, :string,
  #   readable: default,
  #   writable: default,
  #   sortable: default,
  #   filterable: default
  self.attributes_readable_by_default = true
  self.attributes_writable_by_default = true
  self.attributes_sortable_by_default = true
  self.attributes_filterable_by_default = true

  # Used for link generation
  self.base_url = Rails.application.routes.default_url_options[:host]
  # Used for link generation

  self.endpoint_namespace = '/api/'

  # Will raise an error if a resource is being accessed from a URL it is not allowlisted for
  # Helpful for link validation
  self.validate_endpoints = true

  # Automatically generate JSONAPI links?
  self.autolink = false

  before_save :authorize_save
  before_destroy :authorize_destroy

  def base_scope
    super.accessible_by(index_ability)
  end

  # As the cancan abilities are implemented on the basis of instance attributes,
  # we must authorize with initial instance attributes
  def authorize_save(model)
    if model.new_record?
      current_ability.authorize!(:create, model, *model.changed_attributes.keys)
    else
      attrs_from_db = model.attributes.merge(model.attributes_in_database)
      model_from_db = model.class.new(attrs_from_db)
      current_ability.authorize!(:update, model_from_db, *model.changed_attributes.keys)
    end
  end

  def authorize_destroy(model)
    current_ability.authorize! :destroy, model
  end

  delegate :can?, to: :current_ability
  delegate :current_ability, to: :context

  # Used to filter accessible models in `#base_scope`.
  # Overwrite in subclass to use a different Ability instance.
  def index_ability
    current_ability
  end

  def current_user
    current_ability.user
  end
end
