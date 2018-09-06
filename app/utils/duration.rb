# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Duration

  attr_reader :start_at, :finish_at

  def initialize(start_at, finish_at)
    @start_at  = start_at
    @finish_at = finish_at
  end

  def to_s(format = :long)
    if start_at && finish_at
      format_start_finish(format)
    elsif start_at
      format_datetime(start_at)
    elsif finish_at
      format_datetime(finish_at)
    else
      ''
    end
  end

  def active?
    if self.class.date_only?(start_at) && self.class.date_only?(finish_at)
      cover?(Time.zone.today)
    else
      cover?(Time.zone.now)
    end
  end

  def cover?(date)
    if start_at && finish_at
      date.between?(start_at, finish_at)
    elsif finish_at
      date <= finish_at
    elsif start_at
      start_at <= date
    end
  end

  def days
    finish_at ? (start_at.to_date..finish_at.to_date).count : start_at && 1
  end

  def meaningful?
    start_at.blank? || finish_at.blank? || start_at <= finish_at
  end

  def self.date_only?(value)
    !value.respond_to?(:seconds_since_midnight) || value.seconds_since_midnight.zero?
  end

  private

  def format_start_finish(format) # rubocop:disable Metrics/AbcSize
    if start_at == finish_at
      format_datetime(start_at)
    elsif start_at.to_date == finish_at.to_date
      "#{format_date(start_at)} #{format_time(start_at)} - #{format_time(finish_at)}"
    elsif format == :short
      "#{format_date(start_at)} - #{format_date(finish_at)}"
    else
      "#{format_datetime(start_at)} - #{format_datetime(finish_at)}"
    end
  end

  def format_datetime(value)
    if self.class.date_only?(value)
      format_date(value)
    else
      "#{format_date(value)} #{format_time(value)}"
    end
  end

  def format_time(value)
    I18n.l(value, format: :time)
  end

  def format_date(value)
    I18n.l(value.to_date)
  end

  def date_only?(value)
    self.class.date_only?(value)
  end

  deprecate date_only?: "Don't use this private method anymore." \
                        'Instead use the static variant `Duration.date_only?`'

end
