module ActiveModel
  class Name < String
    
    # For STI models, use the base class a route key
    # So only one controller/route for all STI classes is used.
    def initialize_with_sti(*args)
      initialize_without_sti(*args)
      
      if @klass != @klass.base_class
        @param_key = @klass.base_class.model_name.param_key
        @route_key = @klass.base_class.model_name.route_key
        @singular_route_key = ActiveSupport::Inflector.singularize(@route_key).freeze

      end
    end
    
    alias_method_chain :initialize, :sti
  end
end
