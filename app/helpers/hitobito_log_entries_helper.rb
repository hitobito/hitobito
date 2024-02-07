# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

module HitobitoLogEntriesHelper
  def format_message(entry)
    simple_format(entry.message.truncate(1000))
  end

  def format_created_at(entry)
    l(entry.created_at, format: :date_time_millis)
  end

  def hitobito_log_entry_table_attrs
    if category_param
      [:created_at, :level, :subject, :message, :payload]
    else
      [:created_at, :level, :category, :subject, :message, :payload]
    end
  end
end
