# frozen_string_literal: true

#  Copyright (c) 2012-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: user_job_results
#
#  id                                  :bigint           not null, primary key
#  attempts                            :integer          not null
#  end_timestamp                       :datetime
#  filename                            :string
#  filetype                            :string           not null
#  job_class                           :string           not null
#  last_progress_update_broadcasted_at :datetime
#  max_attempts                        :integer          not null
#  progress                            :integer          not null
#  reports_progress                    :boolean          not null
#  start_timestamp                     :datetime         not null
#  status                              :string           not null
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  delayed_job_id                      :bigint
#  person_id                           :bigint           not null
#
# Indexes
#
#  index_user_job_results_on_delayed_job_id  (delayed_job_id)
#  index_user_job_results_on_person_id       (person_id)
#
class UserJobResult < ApplicationRecord
  include I18nEnums

  belongs_to :delayed_job, class_name: "Delayed::Backend::ActiveRecord::Job", optional: true

  scope :unfinished, -> { where(status: UNFINISHED_STATUSES) }

  STATUSES = %w[planned in_progress success error].freeze
  UNFINISHED_STATUSES = %w[planned in_progress].freeze

  i18n_enum :status, STATUSES, queries: true

  belongs_to :person
  has_one_attached :generated_file

  validates_by_schema

  after_initialize :set_default_values, if: :new_record?
  after_save :set_web_socket_connection_state
  after_commit :broadcast_refresh_and_badge_update, on: %i[create destroy]
  after_update_commit :broadcast_replace_and_badge_update

  def to_s
    partial = " (#{progress}%)" if progress.present?

    "<UserJobResult##{id}: #{filename}#{partial}>"
  end

  def downloadable?(downloading_person)
    (person_id == downloading_person.id) && generated_file.attached?
  end

  def write(data, force_encoding: nil)
    io = StringIO.new

    case filetype.to_sym
    when :csv then io.set_encoding(Settings.csv.encoding)
    when :pdf then io.binmode
    end

    io.set_encoding(force_encoding) if force_encoding.present?

    io.write(data)
    io.rewind # make ActiveStorage's checksum-calculation deterministic

    generated_file.attach(io: io, filename:)
  end

  def read
    data = generated_file.download
    if filetype.to_sym == :csv && data.present?
      data = data.force_encoding(Settings.csv.encoding)
    end
    data
  end

  def filename=(filename)
    normalized_filename = filename.to_s.parameterize(preserve_case: true)
    super(normalized_filename)
  end

  def filename
    filename = super
    return if filename.blank?

    "#{filename}.#{filetype}"
  end

  def job_name
    human_job_class_name = job_class.demodulize.underscore.humanize
    I18n.t("delayed_job.#{job_class.underscore}", default: human_job_class_name)
  end

  def report_in_progress!
    update!(status: "in_progress")
  end

  def report_success!(total_attempts)
    update!(
      status: "success",
      end_timestamp: Time.current,
      attempts: total_attempts
    )
    broadcast_notification
  end

  def report_error!(used_attempts)
    update!(
      status: "planned",
      attempts: used_attempts,
      progress: 0
    )
  end

  def report_failure!
    update!(
      status: "error",
      end_timestamp: Time.current
    )
    broadcast_notification
  end

  # Report the progess of the job which is then shown as a progress bar on the
  # user job results view. This could for example be used in a loop that iterates
  # through files or sends out mails.
  #
  # Attention: The <tt>reports_progress</tt> class attribute has to be set to a truthy value
  # on the job class for progress to actually be reported.
  #
  # <tt>current_iteration</tt>: The current iteration
  # <tt>iteration_count</tt>: The total iterations after which the job will be done
  def report_progress!(current_iteration, iteration_count)
    return if !reports_progress || iteration_count.zero?

    # Converted to integer to also handle the nil case
    should_broadcast_update = last_progress_update_broadcasted_at.to_i < 5.seconds.ago.to_i

    attributes_to_update = {
      progress: calculate_progress_percentage(current_iteration, iteration_count),
      last_progress_update_broadcasted_at: (Time.current if should_broadcast_update)
    }.compact

    update_columns(attributes_to_update)
    broadcast_replace_to(update_channel_name) if should_broadcast_update
  end

  private

  def calculate_progress_percentage(current_iteration, iteration_count)
    ((100.to_f / iteration_count) * (current_iteration + 1)).round.clamp(0, 100)
  end

  def set_default_values
    default_values = {
      start_timestamp: Time.current,
      status: "planned",
      filetype: "txt",
      attempts: 0,
      max_attempts: Delayed::Worker.max_attempts,
      reports_progress: false,
      progress: 0
    }

    default_values.each do |k, v|
      send(:"#{k}=", v) if send(k).nil?
    end
  end

  def update_channel_name
    "person_#{person_id}_user_job_result_updates"
  end

  def notification_channel_name
    "person_#{person_id}_user_job_result_notifications"
  end

  def broadcast_replace_and_badge_update
    capturing_redis_exceptions do
      broadcast_replace_to(update_channel_name)
      broadcast_badge_update
    end
  end

  def broadcast_refresh_and_badge_update
    capturing_redis_exceptions do
      broadcast_refresh_to(update_channel_name)
      broadcast_badge_update
    end
  end

  def broadcast_badge_update
    broadcast_replace_to(
      notification_channel_name,
      partial: "user_job_results/link_with_badge",
      locals: {person:},
      target: "user-job-results-link-with-badge"
    )
  end

  def broadcast_notification
    capturing_redis_exceptions do
      broadcast_append_to(
        notification_channel_name,
        partial: "user_job_results/notification",
        locals: {user_job_result: self},
        target: "user-job-result-notifications-container"
      )
    end
  end

  def set_web_socket_connection_state
    if person.user_job_results.unfinished.count > 0
      person.update_column(:needs_web_socket_connection, true)
    else
      person.update_column(:needs_web_socket_connection, false)
    end
  end

  def capturing_redis_exceptions
    yield
  rescue Redis::BaseError => e
    Sentry.capture_exception(e)
  end
end
