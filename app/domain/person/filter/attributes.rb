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
    scope.where(attributes_condition(scope))
  end

  private

  def attributes_condition(scope)
    args.values.map do |v|
      key, constraint, value = v.to_h.symbolize_keys.slice(:key, :constraint, :value).values
      next unless key && value
      next unless Person.filter_attrs.key?(key.to_sym)

      attribute_condition_sql(key, value, constraint, scope)
    end.compact.join(' AND ')
  end

  def attribute_condition_sql(key, value, constraint, scope)
    if Person.column_names.include?(key)
      persisted_attribute_condition_sql(key, value, constraint)
    else
      unpersisted_attribute_condition_sql(key, value, constraint, scope)
    end
  end

  def persisted_attribute_condition_sql(key, value, constraint)
    sql_array = case constraint
                when /match/
                  escaped_value = ActiveRecord::Base.send(:sanitize_sql_like, value.to_s.strip)
                  ["people.#{key} LIKE ?", "%#{escaped_value}%"]
                when /greater/ then ["people.#{key} > ?", value]
                when /smaller/ then ["people.#{key} < ?", value]
                else ["people.#{key} = ?", value]
                end
    ActiveRecord::Base.send(:sanitize_sql_array, sql_array)
  end

  def unpersisted_attribute_condition_sql(key, value, constraint, scope)
    people_ids = scope.map do |p|
      p.id if matching_attribute?(p.send(key), value, constraint)
    end.compact.join(',')

    people_ids = -1 if people_ids.blank?

    <<-SQL.strip_heredoc
      people.id IN (#{people_ids})
    SQL
  end

  def matching_attribute?(attribute, value, constraint)
    case constraint
    when /match/ then attribute.to_s =~ /#{value}/
    when /greater/ then attribute && attribute.to_i > value.to_i
    when /smaller/ then attribute && attribute.to_i < value.to_i
    else attribute.to_s == value
    end
  end
end
