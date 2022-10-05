# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module CalendarsHelper

  def event_type_options(layer)
    layer.event_types.map do |event_type|
      [event_type.model_name.human(count: 2), event_type.to_s]
    end
  end

  def format_calendar_group(calendar_group)
    exclusion = calendar_group.excluded? ? 'excluded' : 'included'
    subgroups = calendar_group.with_subgroups? ? '_with_subgroups' : ''
    I18n.t(
        "calendar_groups.explanation_#{exclusion}#{subgroups}",
        group_name: calendar_group.group.name,
        events: format_event_type(calendar_group.calendar.group, calendar_group.event_type)
    )
  end

  def format_calendar_tags(calendar, excluded:)
    exclusion = excluded ? 'excluded' : 'included'
    tags = excluded ? calendar.excluded_calendar_tags : calendar.included_calendar_tags
    I18n.t(
        "calendars.tags.explanation_#{exclusion}",
        count: tags.count,
        tags: format_tag_list(tags),
        events: format_event_type_all(calendar.group)
    )
  end

  private

  def format_event_type(group, event_type)
    if event_type.blank?
      format_event_type_all(group)
    else
      event_type.constantize.model_name.human(count: 2)
    end
  end

  def format_event_type_all(group)
    group.layer_group.event_types.map { |type| type.model_name.human(count: 2) }.to_sentence
  end

  def format_tag_list(tags)
    word_or = I18n.t('calendars.tags.or')
    tags.map(&:tag).pluck(:name).map { |tag| "\"#{tag}\"" }.to_sentence(
        two_words_connector: word_or,
        last_word_connector: word_or
    )
  end

end
