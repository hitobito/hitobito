#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module UserManageableJob
  extend ActiveSupport::Concern

  prepended do
    class_attribute :job_name, default: name
    class_attribute :reports_progress, default: false
    self.parameters = parameters.to_a + [:user_job_result_id]
  end

  def enqueue!
    current_person = Auth.current_person
    raise "User manageable jobs must be called from context with auth user" unless current_person

    user_job_result = UserJobResult.create!(
      person_id: current_person.id, name: job_name,
      status: "planned", start_timestamp: Time.now.to_i,
      attempts: 0, progress: (reports_progress ? 0 : nil),
      filetype: @format || :txt
    )
    @user_job_result_id = user_job_result.id

    delayed_job = super
    user_job_result.update!(delayed_job:)
    delayed_job
  end

  def before(delayed_job)
    user_job_result&.update!(status: "in_progress")
    super
  end

  def success(job)
    user_job_result&.update!(
      status: "success",
      end_timestamp: Time.now.to_i,
      attempts: job.attempts + 1
    )
    broadcast_notification
    super if defined?(super)
  end

  def failure(job)
    user_job_result&.update!(
      status: "error",
      end_timestamp: Time.now.to_i
    )
    broadcast_notification
    super if defined?(super)
  end

  def error(job, exception, payload = parameters)
    user_job_result&.update!(
      status: "planned",
      attempts: job.attempts + 1,
      progress: (reports_progress ? 0 : nil)
    )
    super
  end

  def report_progress(current_iteration, iteration_count)
    if reports_progress
      progress = (100.to_f / iteration_count) * (current_iteration + 1)
      user_job_result&.update!(progress:)
    end
  end

  def user_job_result
    @user_job_result ||= UserJobResult.find(@user_job_result_id)
  end

  private

  def broadcast_notification
    Turbo::StreamsChannel.broadcast_append_to(
      "user_job_result_notifications",
      partial: "user_job_results/user_job_result_notification",
      locals: {user_job_result:},
      target: "user-job-result-notification-placeholder"
    )
  end
end
