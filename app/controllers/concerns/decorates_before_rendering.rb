# encoding: utf-8

# Copyright (c) 2012 Rob Hanlon, MIT License

#  Copyright (c) 2017, Pfadibewebung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
    klass = __model_class_for__(ivar)
    decorator_name = "#{klass.model_name}Decorator"
    until __decorator_class_exists?(decorator_name)
      klass, decorator_name = __superclass_decorator_name(ivar, klass)
    end
    decorator_name
  end

  def __decorator_class_exists?(decorator_name)
    decorator_name.constantize
    true
  rescue NameError
    false
  end

  def __superclass_decorator_name(ivar, klass)
    superclass = klass.superclass
    if superclass == Module
      raise ArgumentError, "#{ivar} does not have an associated decorator"
    end

    superclass_decorator_name = (superclass == Object ? "Object" : superclass.model_name.to_s)
    superclass_decorator_name += "Decorator"
    [superclass, superclass_decorator_name]
  end

  def __model_class_for__(ivar)
    if ivar.is_a?(ActiveRecord::Relation)
      ivar.klass
    elsif ivar.respond_to?(:each) # Array or Enumerable
      ivar.first.class
    elsif ivar.class.respond_to?(:model_name)
      ivar.class
    else
      raise ArgumentError, "#{ivar.inspect} does not have an associated model"
    end
  end

end
