# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class HitobitoLogger
  def self.categories
    HitobitoLogEntry.categories
  end

  def self.levels
    HitobitoLogEntry.levels.keys
  end

  delegate :categories, :levels, to: 'class'

  levels.each do |level|
    # Log methods for each level
    define_method level do |category, message, subject: nil, payload: nil|
      log(level, category, message, subject, payload)
    end

    # Log methods for each level which replace matching log entries with a new one.
    # Matching means same level, category, message and subject, but payload can be different.
    define_method "#{level}_replace" do |category, message, subject: nil, payload: nil|
      log_replace(level, category, message, subject, payload)
    end
  end

  private

  # Create a log entry
  def log(level, category, message, subject, payload)
    HitobitoLogEntry.create!(
      level: level,
      category: category,
      message: message,
      subject: subject,
      payload: payload
    )
  end

  # Delete all matching log entries
  def unlog(level, category, message, subject)
    HitobitoLogEntry.where(
      level: level,
      category: category,
      message: message,
      subject: subject
    ).delete_all
  end

  # Replace matching log entries with a new one.
  # Matching means same level, category, message and subject, but payload can be different.
  def log_replace(level, category, message, subject, payload)
    HitobitoLogEntry.transaction do
      unlog(level, category, message, subject)
      log(level, category, message, subject, payload)
    end
  end
end
