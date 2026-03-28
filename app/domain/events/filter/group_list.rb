# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Lists event for a certain group
class Events::Filter::GroupList < Events::Filter::List
  attr_reader :group, :range

  def initialize(group, user, params = {})
    super(user, params)
    @group = group
    @range = params[:range]
  end

  def to_h
    params.to_unsafe_h
      .slice(:filters, :range, :type, :year, :start_date, :end_date, :sort_expression)
  end

  def type
    params[:type]
  end

  def year
    params[:year]
  end

  def event_type
    @event_type ||= Event.subclasses.find { |sc| sc.name == type } || Event
  end

  private

  def default_order(events)
    if params[:sort_expression]
      events.list.reorder(Arel.sql(sort_query))
    else
      events.list
    end
  end

  def sort_query
    if params[:sort_expression].is_a?(String)
      params[:sort_expression].gsub(/\b\w+\./, "")
    elsif params[:sort_expression].is_a?(Hash)
      [params[:sort_expression].keys[0].gsub(/\b\w+\./, ""),
        params[:sort_expression].values[0]].join(" ")
    end
  end

  def base_scope
    Event.with_group_id(relevant_group_ids)
      .where(type: params[:type])
      .then { |scope| filter_by_date(scope) }
  end

  def relevant_group_ids
    self_and_descendants = group.self_and_descendants.select(:id)
    case range
    when "group" then [group.id]
    when "layer" then self_and_descendants.where(layer_group_id: group.layer_group_id)
    else self_and_descendants
    end
  end

  def filter_by_date(scope)
    start_date = parse_date(params[:start_date])
    end_date = parse_date(params[:end_date])
    start_time = (start_date || Time.zone.now).beginning_of_day

    if start_date.nil? && end_date.nil?
      scope.in_year(params[:year])
    elsif end_date
      scope.between(start_time, end_date.end_of_day)
    else
      scope.upcoming(start_time)
    end
  end

  private

  def parse_date(date_string)
    date_string.try(:to_date)
  rescue ArgumentError
    nil
  end
end
