module ActiveModel
  class Name < String
    
    # For STI models, use the base class a route key
    # So only one controller/route for all STI classes is used.
    def initialize_with_sti(*args)
      initialize_without_sti(*args)
      
      if @klass != @klass.base_class
        base_name = @klass.base_class.model_name
        @param_key = base_name.param_key
        @route_key = base_name.route_key
        @singular_route_key = base_name.singular_route_key
      elsif @klass.demodulized_route_keys
        @route_key = ActiveSupport::Inflector.pluralize(self.demodulize.underscore).freeze
        @singular_route_key = ActiveSupport::Inflector.singularize(@route_key).freeze
      end
    end
    
    alias_method_chain :initialize, :sti
  end
end

class ActiveRecord::Base
  # set this to true if route_keys should be demodulize
  # e.g. Event::Application -> 'applications'
  class_attribute :demodulized_route_keys
end