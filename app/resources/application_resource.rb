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

  def self.find(params = {}, base_scope = nil)
    # make sure both id params are the same
    # for update since we're checking permission based on
    # params :id
    data_id = params[:data].try(:[], :id).try(:to_i)
    param_id = params[:id].to_i
    if data_id && param_id
      raise ActionController::BadRequest unless data_id == param_id
    end

    super(params, base_scope)
  end

  delegate :can?, to: :context



  def self.attributes_from_active_record(only: [], except: [], writables: [], **opts)
    AttributesBuilder.new(
      self,
      only: Array(only),
      except: Array(except),
      writables: Array(writables),
      **opts
    ).build
  end

  def self.relations_from_active_record(only: [], except: [])
    RelationsBuilder.new(self, only: Array(only), except: Array(except)).build
  end

end
