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

  before_save :authorize_create, only: [:create]
  before_save :authorize_update, only: [:update]
  before_destroy :authorize_destroy

  def base_scope
    # accessible_by selects a subset of attributes. We need to select all attributes,
    # otherwise saving the resource will error when validating unselected attrs.
    # This is achieved by `unscope(:select)`.
    super.accessible_by(index_ability).unscope(:select)
  end

  def authorize_create(model)
    create_ability.authorize!(:create, model)
  end

  # As the cancan abilities are implemented on the basis of instance attributes,
  # we must authorize with initial instance attributes
  def authorize_update(model)
    model_from_db = model.class.find(model.id)
    update_ability.authorize!(:update, model_from_db)
    yield update_ability, model_from_db if block_given?
  end

  def authorize_destroy(model)
    destroy_ability.authorize! :destroy, model
  end

  delegate :can?, to: :current_ability
  delegate :current_ability, to: :context

  # Used to filter accessible models in `#base_scope`.
  def index_ability
    # We require a specific implementation for index_ability in each resource class,
    # because our normal abilities run in memory, which would perform very badly
    # when building the base_scope for the JSON API. (We'd need to load all models
    # from the DB into memory, filter there, and send a complete list of allowed
    # IDs back to the DB.)
    raise 'implement index_ability in the resource class'
  end

  # Meant to be extended in specific resources
  def create_ability
    current_ability
  end

  # Meant to be extended in specific resources
  def update_ability
    current_ability
  end

  # Meant to be extended in specific resources
  def destroy_ability
    current_ability
  end
end
