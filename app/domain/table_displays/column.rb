# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class Column
    attr_reader :template, :table, :model_class, :ability

    def initialize(ability, model_class:, table: nil)
      @ability = ability
      @model_class = model_class
      @table = table
      @template = table&.template
    end

    # Allows a column class to specify which database tables need to be joined for calculating the
    # value
    def required_model_joins(attr)
      resolve_database_joins(attr)
    end

    # Allows a column class to specify which database columns need to be fetched for calculating the
    # value
    def required_model_attrs(_attr)
      raise "implement in subclass"
    end

    def value_for(object, attr, &block)
      target, target_attr = resolve(object, attr)
      if target.present? && target_attr.present?
        if allowed?(target, target_attr, object, attr)
          allowed_value_for(target, target_attr, &block)
        else
          I18n.t("global.not_allowed")
        end
      end
    end

    def label(attr)
      model_class.human_attribute_name(attr)
    end

    # The column class may specify how to sort, by returning a SQL string. Default nil means the
    # column is not sortable.
    def sort_by(_attr)
      nil
    end

    def render(attr)
      raise "implement in subclass, using `super do ... end`" unless block_given?

      table.col(header(attr), data: {attribute_name: attr}) do |object|
        value_for(object, attr) do |target, target_attr|
          yield target, target_attr, object, attr
        end
      end
    end

    def header(attr)
      if sort_by(attr).present?
        table.sort_header(attr, label(attr))
      else
        label(attr)
      end
    end

    protected

    def required_permission(_attr)
      raise "implement in subclass"
    end

    def allowed?(object, attr, _original_object, _original_attr)
      ability.can? required_permission(attr), object
    end

    # Recursively resolve nested attrs
    def resolve(object, path)
      return object, path unless path.to_s.include? "."

      relation, relation_path = path.to_s.split(".", 2)
      resolve(object.try(relation), relation_path)
    end

    def resolve_database_joins(path, model_class = @model_class)
      return {} unless path.to_s.include? "."

      relation, relation_path = path.to_s.split(".", 2)
      relation_class = model_class.reflect_on_association(relation).class_name.constantize
      {relation => resolve_database_column(relation_path, relation_class)}
    end

    def resolve_database_column(path, model_class = @model_class)
      return "#{model_class.table_name}.#{path}" unless path.to_s.include? "."

      relation, relation_path = path.to_s.split(".", 2)
      relation_class = model_class.reflect_on_association(relation).class_name.constantize
      resolve_database_column(relation_path, relation_class)
    end

    def allowed_value_for(target, target_attr, &block)
      if block.present?
        block.call(target, target_attr)
      else
        [target, target_attr]
      end
    end
  end
end
