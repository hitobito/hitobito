# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Filter::Attributes
  extend ActiveSupport::Concern

  included do
    class_attribute :model_class
  end

  def initialize(attr, args)
    @attr = attr
    @args = args
  end

  def apply(scope)
    scope.where(raw_sql_condition(scope))
  end

  private

  def constraints
    @constraints ||= @args.values.select { |tuple| applicable?(tuple) }
  end

  def applicable?(tuple)
    tuple[:key].present? && (tuple[:value].present? || tuple[:constraint] == "blank")
  end

  def generic_constraints
    constraints
  end

  def raw_sql_condition(scope)
    generic_constraints.map do |v|
      key, constraint, value = v.to_h.symbolize_keys.slice(:key, :constraint, :value).values
      next unless model_class.filter_attrs.key?(key.to_sym)

      attribute_condition_sql(key, parse_value(key, value), constraint, scope)
    end.compact.join(" AND ")
  end

  def parse_value(key, value)
    type = model_class.filter_attrs[key.to_sym][:type]
    (type == :date) ? Date.parse(value) : value
  rescue TypeError, Date::Error
    Time.zone.now.to_date
  end

  def attribute_condition_sql(key, value, constraint, scope)
    if model_class.column_names.include?(key)
      persisted_attribute_condition_sql(table_name, key, value, constraint)
    elsif model_class.respond_to?(:translated_attribute_names) &&
        model_class.translated_attribute_names.include?(key.to_sym)
      persisted_attribute_condition_sql(translations_table_name, key, value, constraint)
    else
      unpersisted_attribute_condition_sql(key, value, constraint, scope)
    end
  end

  # include is not a selectable constraint in the current version of the filter view,
  # it is implemented to filter by id's internally for invoice_runs
  def persisted_attribute_condition_sql(table, column, value, constraint)
    sql_string = case constraint
    when /match/
      match_search_sql(table, column, value, constraint)
    when /blank/
      "COALESCE(TRIM(#{table}.#{column}::text), '') #{sql_comparator(constraint)} ?"
    when /include/
      "#{table}.#{column} IN (?)"
    else
      "#{table}.#{column} #{sql_comparator(constraint)} ?"
    end

    ActiveRecord::Base.sanitize_sql_array([sql_string, sql_value(column, value, constraint)])
  end

  def match_search_sql(table, column, value, constraint)
    if value.is_a?(Numeric)
      "CAST(#{table}.#{column} AS TEXT) #{sql_comparator(constraint)} ?"
    else
      "#{table}.#{column} #{sql_comparator(constraint)} ?"
    end
  end

  def sql_comparator(constraint)
    case constraint.to_s
    when "match" then "LIKE"
    when "not_match" then "NOT LIKE"
    when "greater", "after" then ">"
    when "smaller", "before" then "<"
    when "equal", "blank" then "="
    else raise("unexpected constraint: #{constraint.inspect}")
    end
  end

  def sql_value(key, value, constraint)
    case constraint.to_s
    when "match", "not_match"
      "%#{ActiveRecord::Base.send(:sanitize_sql_like, value.to_s.strip)}%"
    when "blank"
      ""
    when "include"
      value
    when "equal", "greater", "smaller", "before", "after"
      (key == "email") ? value.downcase : value
    else
      raise("unexpected constraint: #{constraint.inspect}")
    end
  end

  def unpersisted_attribute_condition_sql(key, value, constraint, scope)
    model_ids = scope.map do |record|
      record.id if matching_attribute?(record.send(key), value, constraint)
    end.compact.join(",")

    model_ids = -1 if model_ids.blank?

    "#{table_name}.id IN (#{model_ids})"
  end

  def matching_attribute?(attribute, value, constraint) # rubocop:todo Metrics/CyclomaticComplexity
    case constraint
    when "match" then attribute.to_s =~ /#{value}/
    when "not_match" then attribute.to_s !~ /#{value}/
    when "greater" then attribute && attribute.to_i > value.to_i
    when "smaller" then attribute && attribute.to_i < value.to_i
    when "blank" then attribute.blank?
    else attribute.to_s == value
    end
  end

  def table_name
    model_class.table_name
  end

  def translations_table_name
    model_class.translations_table_name
  end
end
