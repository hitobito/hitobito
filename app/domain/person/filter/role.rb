# frozen_string_literal: true

#  Copyright (c) 2017-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Role < Person::Filter::Base
  KINDS = %w[active created deleted inactive]

  include ParamConverters

  self.permitted_args = [:role_type_ids, :role_types, :kind,
    :start_at, :finish_at, :include_archived]

  def initialize(attr, args)
    super
    initialize_role_types
  end

  def apply(scope)
    scope = scope
      .where(type_conditions(scope))
      .where(duration_conditions(scope))
    if include_archived?
      scope
    else
      scope.where(roles: {archived_at: nil})
        .or(scope.where(Role.arel_table[:archived_at].gt(Time.now.utc)))
    end
  end

  def blank?
    args[:role_type_ids].blank? && args[:kind].blank? && args[:include_archived].blank?
  end

  def to_hash
    merge_duration_args(role_types: args[:role_types])
  end

  def to_params
    merge_duration_args(role_type_ids: args[:role_type_ids].join(ID_URL_SEPARATOR))
  end

  def roles_join
    <<~SQL.split.map(&:strip).join(" ")
      INNER JOIN roles ON roles.person_id = people.id
      INNER JOIN #{Group.quoted_table_name} ON roles.group_id = #{Group.quoted_table_name}.id
    SQL
  end

  def date_range
    start_day = parse_day(args[:start_at], Time.zone.at(0).to_date)
    finish_day = parse_day(args[:finish_at], Date.current)

    start_day..finish_day
  end

  private

  def parse_day(date, default)
    Date.parse(date.presence)
  rescue ArgumentError, TypeError
    default.to_date
  end

  def merge_duration_args(hash)
    hash.merge(args.slice(:kind, :start_at, :finish_at, :include_archived))
  end

  def initialize_role_types
    classes = role_classes
    args[:role_type_ids] = classes.map(&:id)
    args[:role_types] = classes.map(&:sti_name)
  end

  def role_classes
    if args[:role_types].present?
      role_classes_from_types
    else
      Role.types_by_ids(id_list(:role_type_ids))
    end
  end

  def role_classes_from_types
    role_map = Role.all_types.index_by(&:sti_name)
    args[:role_types].map { |t| role_map[t] }.compact
  end

  def type_conditions(scope)
    return if args[:role_types].blank?

    ["roles.type IN (?)", args[:role_types]]
  end

  def duration_conditions(scope)
    case args[:kind]
    when "created" then [[:roles, {start_on: date_range}]].to_h
    when "deleted" then [[:roles, {end_on: date_range}]].to_h
    when "active" then [active_role_condition, min: date_range.min, max: date_range.max]
    when "inactive" then no_active_role_conditions(scope)
    else [active_role_condition, min: today, max: today]
    end
  end

  def active_role_condition
    <<~SQL.split.map(&:strip).join(" ")
      (roles.start_on <= :max OR roles.start_on IS NULL) AND
      (roles.end_on >= :min OR roles.end_on IS NULL)
    SQL
  end

  def no_active_role_conditions(scope)
    min_date = parse_day(args[:start_at], today)
    max_date = parse_day(args[:finish_at], today)
    excluded_people_ids = scope.where(active_role_condition, min: min_date, max: max_date)
      .where(roles: {type: args[:role_types]})
      .pluck(:id)

    ["people.id NOT IN (?)", excluded_people_ids] if excluded_people_ids.present?
  end

  def include_archived?
    true?(args[:include_archived])
  end

  def today
    @today ||= Date.current
  end
end
