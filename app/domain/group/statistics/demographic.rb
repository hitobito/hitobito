# frozen_string_literal: true

#  Copyright (c) 2017-2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::Statistics::Demographic < Group::Statistics::Base
  self.key = :people
  self.permitted_params = [:year]

  AgeGroup = Struct.new(:year, :age, :count, :relative_count, keyword_init: true)

  NIL_SORT_VALUE = 10_000

  def age_groups
    @age_groups ||= build_age_groups
  end

  def year
    @year ||= filter_params[:year]&.to_i || Date.current.year
  end

  def total_count
    @total_count ||= age_groups.map(&:count).sum
  end

  def max_relative_count
    @max_relative_count ||= age_groups.map(&:relative_count).max
  end

  def group_names
    layer.groups_in_same_layer.map(&:to_s)
  end

  private

  def build_age_groups
    years(layer)
      .yield_self { |years| histogram(years) }
      .map do |birth_year, (count, relative_count)|
        age = birth_year.nil? ? nil : year - birth_year
        AgeGroup.new(year: birth_year, age: age, count: count, relative_count: relative_count)
      end
  end

  def years(layer)
    group_ids = layer.groups_in_same_layer.select(:id)
    birthdays = Person.joins(:roles).where(roles: {group_id: group_ids}).pluck(:birthday)
    birthdays.map { |date| date&.year }
  end

  def histogram(values)
    total = 0.0
    values.each_with_object(Hash.new(0)) { |value, memo|
      memo[value] += 1
      total += 1
    }
      .transform_values { |absolute| [absolute, absolute / total] }
      .to_a
      .sort_by { |value, _count| value || NIL_SORT_VALUE }
  end
end
