# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class PolymorphicColumn < Column
    SUBTYPE_MAPPINGS = {
      participant: %w[Person ::Event::Guest]
    }

    def label(attr)
      return super if attr.to_s.exclude?(".")

      read_label_from_subtypes(*resolve_path(attr))
    end

    protected

    def resolve_database_joins(path, model_class = @model_class) # rubocop:todo Metrics/AbcSize
      relation, column_name = resolve_path(path)
      association = model_class.reflect_on_association(relation)

      subselects = SUBTYPE_MAPPINGS[relation.to_sym].each do |type_model|
        [type_model.tableize.tr("/", "_"), type_model]
      end.map do |table, type|
        "SELECT #{table}.#{column_name}, '#{type}' AS type FROM #{table}"
      end

      <<~SQL.squish
        LEFT JOIN (#{subselects.join(" UNION ")}) AS #{relation}
        ON #{relation}.id = #{model_class.table_name}.#{association.foreign_key}
        AND #{relation}.type = #{model_class.table_name}.#{association.foreign_type}
      SQL
    end

    def resolve_database_column(path, model_class = @model_class)
      path.to_s
    end

    def resolve_path(path)
      return {} unless path.to_s.include? "."

      path.to_s.split(".").tap do |path_parts|
        raise "Error in TableDisplay-configuration" if path_parts.count > 2
      end
    end

    def read_label_from_subtypes(relation, column_name)
      model_classes = SUBTYPE_MAPPINGS[relation.to_sym].map do |klass|
        Object.const_get(klass) # constanize would return TableDisplays::Event
      end

      model_classes
        .find { |c| c.new.respond_to?(column_name) }
        &.human_attribute_name(column_name)
    end
  end
end
