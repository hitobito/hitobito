# frozen_string_literal: true

#  Copyright (c) 2017-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Role < Person::Filter::Base
  KINDS = %w[active created deleted inactive inactive_but_existing]

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
    # { roles: :group } would include the default scopes and thus only active roles.
    # join all roles ignoring their date ranges here.
    <<~SQL.squish
      INNER JOIN roles ON roles.person_id = people.id
      INNER JOIN groups ON roles.group_id = groups.id
    SQL
  end

  def date_range
    @date_range ||= begin
      default_start = default_range_today? ? today : Date.new(1900)
      start_day = parse_day(args[:start_at], default_start)
      finish_day = parse_day(args[:finish_at], today)

      start_day..finish_day
    end
  end

  private

  def parse_day(date, default)
    Date.parse(date.presence)
  rescue ArgumentError, TypeError
    default
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
    return if args[:role_types].blank? || args[:kind] == "inactive"

    ["roles.type IN (?)", args[:role_types]]
  end

  def duration_conditions(scope)
    case args[:kind]
    when "created" then {roles: {start_on: date_range}}
    when "deleted" then {roles: {end_on: date_range}}
    when "inactive", "inactive_but_existing" then inactive_role_conditions(scope)
    else active_role_condition
    end
  end

  def active_role_condition
    [
      "(roles.start_on <= :max OR roles.start_on IS NULL) AND " \
      "(roles.end_on >= :min OR roles.end_on IS NULL)",
      min: date_range.min,
      max: date_range.max
    ]
  end

  def inactive_role_conditions(scope)
    excluded_people_ids = scope.where(active_role_condition)
      .where(roles: {type: args[:role_types]})
      .pluck(:id)

    ["people.id NOT IN (?)", excluded_people_ids] if excluded_people_ids.present?
  end

  def include_archived?
    true?(args[:include_archived])
  end

  def default_range_today?
    !%w[active created deleted].include?(args[:kind])
  end

  def today
    @today ||= Date.current
  end
end
