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
  # Suggest referencing this config/routes.rb:
  # scope path: ApplicationResource.endpoint_namespace do
  #   resources :posts
  # end
  self.endpoint_namespace = '/api/'

  # Will raise an error if a resource is being accessed from a URL it is not allowlisted for
  # Helpful for link validation
  self.validate_endpoints = true

  # Automatically generate JSONAPI links?
  self.autolink = true
end
