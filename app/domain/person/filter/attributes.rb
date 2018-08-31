#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Attributes < Person::Filter::Base

  MATCH = 'match'.freeze

  def initialize(attr, args)
    @attr = attr
    @args = args
  end

  def apply(scope)
    scope.where(attributes_condition(scope))
  end

  private

  def attributes_condition(scope)
    args.map do |_k, v|
      next unless v[:value] && v[:key]
      next unless Person.filter_attrs_list.map(&:second).map(&:to_s).include?(v[:key])

      attribute_condition_sql(v[:key], v[:value], v[:constraint], scope)
    end.join(' AND ')
  end

  def attribute_condition_sql(key, value, constraint, scope)
    match = constraint == MATCH

    if Person.column_names.include?(key)
      persisted_attribute_condition_sql(key, value, match)
    else
      unpersisted_attribute_condition_sql(key, value, match, scope)
    end
  end

  def persisted_attribute_condition_sql(key, value, match)
    sql_array = if match
                  escaped_value = ActiveRecord::Base.send(:sanitize_sql_like, value.to_s.strip)
                  ["people.#{key} LIKE ?", "%#{escaped_value}%"]
                else
                  ["people.#{key} = ?", value]
                end

    ActiveRecord::Base.send(:sanitize_sql_array, sql_array)
  end

  def unpersisted_attribute_condition_sql(key, value, match, scope)
    people_ids = scope.map do |p|
      p.id if matching_attribute?(p.send(key), value, match)
    end.compact.join(',')

    people_ids = -1 if people_ids.blank?

    <<-SQL.strip_heredoc
      people.id IN (#{people_ids})
    SQL
  end

  def matching_attribute?(attribute, value, match)
    if match
      attribute.to_s =~ /#{value}/
    else
      attribute.to_s == value
    end
  end

end
