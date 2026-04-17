# frozen_string_literal: true

#  Copyright (c) 2012-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: async_download_files
#
#  id         :bigint           not null, primary key
#  filetype   :string
#  name       :string           not null
#  progress   :integer
#  timestamp  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  person_id  :integer          not null
#

class UserJobResult < ApplicationRecord
  include I18nEnums

  STATUSES = %w[planned in_progress success error].freeze

  belongs_to :delayed_job, class_name: "Delayed::Backend::ActiveRecord::Job", optional: true

  has_one_attached :generated_file

  i18n_enum :status, STATUSES, queries: true

  after_update_commit -> { broadcast_replace_to "user_job_results" }
  after_create_commit -> { broadcast_refresh_to "user_job_results" }
  after_destroy_commit -> { broadcast_refresh_to "user_job_results" }

  before_destroy do
    generated_file.purge if generated_file.attached?
  end

  def self.create_default!(person_id, job_name, filename, filetype, reports_progress)
    create!(
      person_id:,
      name: job_name,
      filename:,
      filetype: filetype || :txt,
      reports_progress:,
      progress: (reports_progress ? 0 : nil),
      status: "planned",
      attempts: 0,
      start_timestamp: Time.now.to_i
    )
  end

  def to_s
    partial = " (#{progress}%)" if progress.present?

    "<UserJobResult##{id}: #{filename}#{partial}>"
  end

  def downloadable?(person)
    (person_id == person.id) && generated_file.attached?
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
    "#{super}.#{filetype}"
  end

  def report_in_progress!
    update!(status: "in_progress")
  end

  def report_success!(total_attempts)
    update!(
      status: "success",
      end_timestamp: Time.now.to_i,
      attempts: total_attempts
    )
    broadcast_notification
  end

  def report_error!(used_attempts)
    update!(
      status: "planned",
      attempts: used_attempts,
      progress: (reports_progress ? 0 : nil)
    )
  end

  def report_failure!
    update!(
      status: "error",
      end_timestamp: Time.now.to_i
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
    if reports_progress
      progress = (100.to_f / iteration_count) * (current_iteration + 1)
      progress = (0 if progress < 0) || (100 if progress > 100) || progress
      update!(progress:)
    end
  end

  private

  def broadcast_notification
    Turbo::StreamsChannel.broadcast_append_to(
      "user_job_result_notifications",
      partial: "user_job_results/user_job_result_notification",
      locals: {user_job_result: self},
      target: "user-job-result-notification-placeholder"
    )
  end
end
