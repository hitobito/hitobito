# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Calendars::Events

  delegate :included_calendar_groups, :excluded_calendar_groups,
           :included_calendar_tags, :excluded_calendar_tags,
           :id, to: '@calendar'

  attr_reader :calendar

  def initialize(calendar)
    @calendar = calendar
  end

  def events
    query = Event.includes([:dates, :translations, :contact])

    # Inclusion and exclusion of events based on groups
    query = query.joins(:groups).distinct.where(groups_conditions(included_calendar_groups))
    query = query.where(groups_conditions(excluded_calendar_groups).not) if excluded_groups_exist?

    # Inclusion and exclusion of events based on tags
    query = query.joins(:taggings).where(included_tags_condition) if included_tags_exist?
    query = query.where(excluded_tags_condition) if excluded_tags_exist?

    query
  end

  private

  def excluded_groups_exist?
    @excluded_calendar_groups_exist = excluded_calendar_groups.exists?
  end

  def included_tags_exist?
    @included_calendar_tags_exist = included_calendar_tags.exists?
  end

  def excluded_tags_exist?
    @excluded_calendar_tags_exist = excluded_calendar_tags.exists?
  end

  def groups_conditions(calendar_groups)
    calendar_groups.map { |calendar_group| groups_condition(calendar_group) }.reduce(&:or)
  end

  def groups_condition(calendar_group)
    hierarchy = hierarchy_condition(calendar_group)
    return hierarchy unless calendar_group.event_type.present?

    hierarchy.and(event_type_condition(calendar_group))
  end

  def hierarchy_condition(calendar_group)
    groups = Group.arel_table
    return groups[:id].eq(calendar_group.group.id) unless calendar_group.with_subgroups

    groups[:lft].gteq(calendar_group.group.lft)
        .and(groups[:rgt].lteq(calendar_group.group.rgt))
  end

  def event_type_condition(calendar_group)
    events = Event.arel_table
    event = Arel.sql("'Event'")
    # special case for plain Events: type is NULL in the database
    Arel::Nodes::NamedFunction.new('IFNULL', [events[:type], event]).eq(calendar_group.event_type)
  end

  def included_tags_condition
    { taggings: { tag_id: included_calendar_tags.pluck(:tag_id) } }
  end

  def excluded_tags_condition
    ActsAsTaggableOn::Tagging
        .where(taggable_type: 'Event')
        .where('taggable_id = events.id')
        .where(tag_id: excluded_calendar_tags.pluck(:tag_id))
        .arel.exists.not
  end
end
