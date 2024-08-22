# frozen_string_literal: true

#  Copyright (c) 2017-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Role < Person::Filter::Base
  include ParamConverters

  self.permitted_args = [:role_type_ids, :role_types, :kind,
    :start_at, :finish_at, :include_archived]

  def initialize(attr, args)
    super
    initialize_role_types
  end

  def apply(scope)
    scope = scope.where(type_conditions(scope))
      .where(duration_conditions)
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
    case args[:kind]
    when "active", "inactive" then any_roles_join
    when "deleted" then ended_roles_join
    end
  end

  def date_range
    start_day = parse_day(args[:start_at], Time.zone.at(0))
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
    return inactive_type_conditions(scope) if args[:kind].eql?("inactive")

    [[:roles, {type: args[:role_types]}]].to_h
  end

  def inactive_type_conditions(scope)
    excluded_people_ids = scope.where(excluded_roles_duration_conditions)
      .where(roles: {type: args[:role_types]})
      .pluck(:id)

    ["people.id NOT IN (?)", excluded_people_ids] if excluded_people_ids.any?
  end

  def excluded_roles_duration_conditions
    [active_role_condition, {
      min: parse_day(args[:start_at], Date.current),
      max: parse_day(args[:finish_at], Date.current)
    }]
  end

  def duration_conditions
    return unless args[:kind]

    case args[:kind]
    when "created" then [[:roles, {start_on: date_range}]].to_h
    when "deleted" then [[:roles, {end_on: date_range}]].to_h
    when "active", "inactive" then [active_role_condition, min: date_range.min, max: date_range.max]
    end
  end

  def active_role_condition
    <<~SQL.split.map(&:strip).join(" ")
      (roles.start_on <= :max OR roles.start_on IS NULL) AND
      (roles.end_on >= :min OR roles.end_on IS NULL)
    SQL
  end

  def ended_roles_join
    # TODO: this query was designed to use with paranoia attr deleted_at. Does this still make sense
    # with end_on without providing a reference date?
    <<~SQL.split.map(&:strip).join(" ")
      INNER JOIN roles ON
        (roles.person_id = people.id AND roles.end_on IS NOT NULL)
      INNER JOIN #{Group.quoted_table_name} ON roles.group_id = #{Group.quoted_table_name}.id
    SQL
  end

  def any_roles_join
    <<~SQL.split.map(&:strip).join(" ")
      INNER JOIN roles ON roles.person_id = people.id
      INNER JOIN #{Group.quoted_table_name} ON roles.group_id = #{Group.quoted_table_name}.id
    SQL
  end

  def include_archived?
    true?(args[:include_archived])
  end
end
