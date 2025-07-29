# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class CursorBasedPagingJob < BaseJob
  class_attribute :batch_size, default: 1_000
  class_attribute :reschedule_offset, default: 15.seconds
  class_attribute :progress_message, default: "#{self.class}: Fortschritt %d%%"
  class_attribute :error_message, default: "#{self.class}: Fehler bei %d"
  class_attribute :log_category, default: :cleanup

  self.parameters = [:cursor, :processed_count, :processing_count]
  attr_reader :cursor, :processing_count, :processed_count, :data

  def initialize(cursor: nil, processed_count: 0, processing_count: 0)
    @cursor = cursor
    @processed_count = processed_count
    @processing_count = processing_count
  end

  def perform
    if cursor.nil?
      perform_initial
    else
      perform_rescheduled
    end
  end

  private

  def perform_rescheduled
    case check_batch
    when :processing
      reschedule
    when :finished
      process_result
      process_next_batch
    when :error
      log_error
      process_next_batch
    end
  end

  def perform_initial
    process_next_batch
    log_progress(0) if list.present?
  end

  def process_next_batch
    if list.none?
      log_progress(100) if cursor
      return
    end
    attrs = yield
    reschedule(attrs)
    update_progress
  end

  def update_progress
    percent = floored_percent(processed_count + processing_count)
    return if percent == floored_percent(processed_count)

    log_progress(percent)
  end

  def list
    @list ||= scope.limit(batch_size).then do |scope|
      next scope unless cursor
      scope.where("#{scope.table_name}.id > ?", cursor)
    end
  end

  def log_error(message = nil)
    HitobitoLogEntry.create!(
      category: log_category,
      level: :error,
      message: message || format(error_message, cursor)
    )
  end

  def log_progress(percent)
    HitobitoLogEntry.create!(
      level: :info,
      category: log_category,
      message: format(progress_message, percent)
    )
  end

  def reschedule(attrs = {cursor:, processed_count:, processing_count:})
    self.class.new(**attrs).enqueue!(run_at: reschedule_offset.from_now)
  end

  def floored_percent(count) = ((count / total.to_f) * 100).floor(-1)

  def total = @total ||= scope.count

  def initial_run? = cursor.nil?
end
