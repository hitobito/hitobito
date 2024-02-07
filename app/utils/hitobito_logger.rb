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
    define_method level do |category, message, subject: nil, payload: nil|
      log(level, category, message, subject: subject, payload: payload)
    end
  end

  private

  def log(level, category, message, subject: nil, payload: nil)
    HitobitoLogEntry.create!(
      level: level,
      category: category,
      message: message,
      subject: subject,
      payload: payload
    )
  end
end
