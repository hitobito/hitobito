# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class RedateJob < BaseJob
  SZ = "date_part('hour', created_at) >= 22 AND date_part('month', created_at) IN (3,4,5,6,7,8,9,10)"
  WZ = "date_part('hour', created_at) >= 23 AND date_part('month', created_at) IN (10,11,12,1,2,3)"

  def perform
    roles_requiring_start_on_change.each do |role, start_on|
      update_columns(role, start_on:)
    end

    roles_requiring_end_on_change.each do |role, end_on|
      update_columns(role, end_on:)
    end

    nil
  end

  private

  def roles_requiring_start_on_change
    roles_from_create_events
      .select { |role| off_by_one?(role.created_at, role.start_on) }
      .map { |role| [role, role.created_at.to_date] }
  end

  def roles_requiring_end_on_change
    roles_from_destroy_events
      .select { |role| off_by_one?(role_destroy_events[role.id].created_at, role.end_on) }
      .map { |role| [role, role_destroy_events[role.id].created_at.to_date] }
  end

  def update_columns(role, **attrs)
    key, value = attrs.first
    message = formatted(role.person.to_s + " (#{role.person.id})")

    message << " -  #{formatted([role.group.layer_group.to_s, role.group.to_s, role.to_s].join(" / "), cap_at: 100)}"
    message << ": #{key} (#{role.send(key)} -> #{value})"
    role.update_columns(attrs)
    Rails.logger.info message
  end

  def formatted(str, cap_at: 30) = str.truncate(cap_at).ljust(cap_at)

  def off_by_one?(datetime, date)
    return false if datetime.nil? || date.nil?

    (datetime.to_date - date).to_i == 1
  end

  def roles_from_create_events
    role_scope
      .where("created_at IS NOT NULL AND start_on IS NOT NULL")
      .where([SZ, WZ].join(" OR "))
  end

  def roles_from_destroy_events = role_scope.where(id: role_destroy_events.keys)

  def role_scope = Role.with_inactive
    .includes(:person, group: [:layer_group, :translations])
    .order(:person_id, created_at: :desc)

  def role_destroy_events
    @role_destroy_events ||= PaperTrail::Version
      .where(event: :destroy, item_type: "Role")
      .where([SZ, WZ].join(" OR "))
      .index_by(&:item_id)
  end
end
