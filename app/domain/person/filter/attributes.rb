#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Attributes < Person::Filter::Base
  def initialize(attr, args)
    @attr = attr
    @args = args
  end

  def apply(scope)
    scope.where(raw_sql_condition(scope)).merge(years_scope)
  end

  private

  def constraints
    @args.values.select { |tuple| tuple[:key].present? && tuple[:value].present? }
  end

  def years_constraint
    @years_constraint ||= constraints.find { |tuple| tuple[:key] == "years" }
  end

  def generic_constraints
    @generic_constraints ||= constraints - [years_constraint]
  end

  def years_scope
    return Person.all unless years_constraint

    value, constraint = years_constraint.values_at("value", "constraint")
    value = value.to_i
    case constraint.to_s
    when "greater" then years_greater_scope(value)
    when "smaller" then years_smaller_scope(value)
    when "equal" then years_equal_scope(value)
    else raise("unexpected constraint: #{constraint.inspect}")
    end
  end

  def years_smaller_scope(value)
    date_value = Time.zone.now.to_date - value.to_i.years
    Person.where("birthday > ?", date_value)
  end

  def years_greater_scope(value)
    # Account for weird definition of age, depending on greater_than comparison...
    date_value = Time.zone.now.to_date - value.to_i.years - 1.year + 1.day
    Person.where(birthday: ...date_value)
  end

  def years_equal_scope(value)
    years_smaller_scope(value + 1).merge(years_greater_scope(value - 1))
  end

  def raw_sql_condition(scope)
    generic_constraints.map do |v|
      key, constraint, value = v.to_h.symbolize_keys.slice(:key, :constraint, :value).values
      next unless Person.filter_attrs.key?(key.to_sym)
      type = Person.filter_attrs[key.to_sym][:type]
      begin
        parsed_value = (type == :date) ? Date.parse(value) : value
      rescue Date::Error
        parsed_value = Time.zone.now.to_date
      end

      attribute_condition_sql(key, parsed_value, constraint, scope)
    end.compact.join(" AND ")
  end

  def attribute_condition_sql(key, value, constraint, scope)
    if Person.column_names.include?(key)
      persisted_attribute_condition_sql(key, value, constraint)
    else
      unpersisted_attribute_condition_sql(key, value, constraint, scope)
    end
  end

  def persisted_attribute_condition_sql(key, value, constraint)
    sql_array = if value.is_a?(Numeric) && (constraint == "match" || constraint == "not_match")
      ["CAST(people.#{key} AS TEXT) #{sql_comparator(constraint)} ?", sql_value(value, constraint)]
    else
      ["people.#{key} #{sql_comparator(constraint)} ?", sql_value(value, constraint)]
    end
    ActiveRecord::Base.sanitize_sql_array(sql_array)
  end

  def sql_comparator(constraint)
    case constraint.to_s
    when "match" then "LIKE"
    when "not_match" then "NOT LIKE"
    when "greater" then ">"
    when "smaller" then "<"
    when "equal" then "="
    else raise("unexpected constraint: #{constraint.inspect}")
    end
  end

  def sql_value(value, constraint)
    case constraint.to_s
    when "match", "not_match"
      "%#{ActiveRecord::Base.send(:sanitize_sql_like, value.to_s.strip)}%"
    when "equal", "greater", "smaller" then value
    else raise("unexpected constraint: #{constraint.inspect}")
    end
  end

  def unpersisted_attribute_condition_sql(key, value, constraint, scope)
    people_ids = scope.map do |p|
      p.id if matching_attribute?(p.send(key), value, constraint)
    end.compact.join(",")

    people_ids = -1 if people_ids.blank?

    <<~SQL
      people.id IN (#{people_ids})
    SQL
  end

  def matching_attribute?(attribute, value, constraint)
    case constraint
    when "match" then attribute.to_s =~ /#{value}/
    when "not_match" then attribute.to_s !~ /#{value}/
    when "greater" then attribute && attribute.to_i > value.to_i
    when "smaller" then attribute && attribute.to_i < value.to_i
    else attribute.to_s == value
    end
  end
end
