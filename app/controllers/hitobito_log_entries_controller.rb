# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class HitobitoLogEntriesController < ListController
  helper_method :category_param

  private

  def model_scope
    model_class.
      includes(:subject).
      yield_self(&method(:filter_category)).
      yield_self(&method(:filter_from)).
      yield_self(&method(:filter_to)).
      yield_self(&method(:filter_level)).
      order(created_at: :desc).
      page(params[:page])
  end

  %i[category level from_date from_time to_date to_time].each do |p|
    define_method("#{p}_param") do
      params[p].presence
    end
  end

  %i[date time].each do |c|
    define_method("#{c}_param") do |type|
      send("#{type}_#{c}_param")
    end
  end

  def date_param(type)
    send("#{type}_date_param")
  end

  def filter_category(scope)
    category_param ? scope.where(category: category_param) : scope
  end

  def filter_time(type)
    return unless date_param(type) || time_param(type)

    date = date_param(type) || Date.today
    time_of_day = time_param(type) || (type == :from ? '00:00' : '23:59')
    Time.zone.parse("#{date} #{time_of_day}")
  end

  def filter_from(scope)
    filter_time(:from) ? scope.where('created_at >= ?', filter_time(:from)) : scope
  end

  def filter_to(scope)
    return scope unless filter_time(:to)

    # The param has minute precision. We add 1 minute and
    # do a `<` comparison, so we also get the entries created
    # after this exact minute but before the next minute which is
    # what the user expects when having minute precision.
    less_than_timestamp = filter_time(:to) + 1.minute
    scope.where('created_at < ?', less_than_timestamp)
  end

  def filter_level(scope)
    return scope unless level_param

    scope.where('level >= ?', HitobitoLogEntry.levels[level_param])
  end
end
