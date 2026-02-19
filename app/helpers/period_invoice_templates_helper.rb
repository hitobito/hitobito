# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PeriodInvoiceTemplatesHelper
  def format_recipient_group_type(period_invoice_template)
    period_invoice_template.recipient_group_type.constantize.model_name.human(count: 2)
  end

  def format_calendar_tags(calendar, excluded:)
    exclusion = excluded ? "excluded" : "included"
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
    word_or = I18n.t("calendars.tags.or")
    tags.map(&:tag).pluck(:name).map { |tag| "\"#{tag}\"" }.to_sentence(
      two_words_connector: word_or,
      last_word_connector: word_or
    )
  end
end
