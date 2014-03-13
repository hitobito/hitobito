# encoding: utf-8

# Copyright (c) 2012 Rob Hanlon, MIT License


module Concerns
  # Decorates the specified fields. For instance, if you have
  #
  #   class StuffController < ApplicationController
  #     include DecoratesBeforeRendering
  #
  #     decorates :thing_1, :thing_2
  #   end
  #
  # @thing_1 and @thing_2 will be decorated right before a rendering occurs.
  #
  module DecoratesBeforeRendering
    extend ActiveSupport::Concern

    included do
      class_attribute :__ivars_to_decorate__, instance_accessor: false
    end

    module ClassMethods
      def decorates(*unsigiled_ivar_names)
        self.__ivars_to_decorate__ = unsigiled_ivar_names.map { |i| "@#{i}" }
      end
    end

    def render(*args)
      __decorate_ivars__
      super(*args)
    end

    private

    def __decorate_ivars__
      ivars_to_decorate = self.class.__ivars_to_decorate__

      return if ivars_to_decorate.nil?

      ivars_to_decorate.each do |ivar_name|
        ivar = instance_variable_get(ivar_name)
        instance_variable_set(ivar_name, __decorator_for__(ivar)) unless ivar.nil?
      end
    end

    def __decorator_for__(ivar)
      decorator_class = __decorator_name_for__(ivar).constantize
      if ivar.respond_to?(:each)
        if ivar.respond_to?(:current_page)
          PaginatingDecorator.new(ivar, with: decorator_class)
        else
          decorator_class.decorate_collection(ivar)
        end
      else
        decorator_class.decorate(ivar)
      end
    end

    def __decorator_name_for__(ivar)
      org_ivar = ivar
      decorator_name = "#{__model_name_for__(ivar)}Decorator"
      while (decorator_name.constantize rescue nil) == nil
        superclass = ivar.respond_to?(:model_name) ? ivar.superclass : ivar.class.superclass
        fail ArgumentError, "#{org_ivar} does not have an associated decorator" if superclass == Module
        superclass_decorator_name = (superclass == Object ? 'Object' : superclass.model_name.to_s)
        superclass_decorator_name += 'Decorator'
        ivar = superclass
        decorator_name = superclass_decorator_name
      end
      decorator_name
    end

    def __model_name_for__(ivar)
      if ivar.respond_to?(:model_name)
        ivar
      elsif ivar.class.respond_to?(:model_name)
        ivar.class
      else
        fail ArgumentError, "#{ivar} does not have an associated model"
      end.model_name
    end

  end
end
