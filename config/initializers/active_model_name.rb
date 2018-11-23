# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ActiveModel
  class Name

    module Sti
      # For STI models, use the base class a route key
      # So only one controller/route for all STI classes is used.
      def initialize(*args)
        super(*args)
      return if @klass == Oauth::Application

        if @klass != @klass.base_class
          base_name = @klass.base_class.model_name
          @param_key = base_name.param_key
          @route_key = base_name.route_key
          @singular_route_key = base_name.singular_route_key
        elsif @klass.demodulized_route_keys
          @route_key = ActiveSupport::Inflector.pluralize(name.demodulize.underscore).freeze
          @singular_route_key = ActiveSupport::Inflector.singularize(@route_key).freeze
        end
      end
    end

    prepend ActiveModel::Name::Sti
  end
end

class ActiveRecord::Base
  # set this to true if route_keys should be demodulize
  # e.g. Event::Application -> 'applications'
  class_attribute :demodulized_route_keys
end
