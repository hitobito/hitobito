#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module UserManageableJob
  extend ActiveSupport::Concern

  prepended do
    attr_writer :user_id
    class_attribute :job_name, default: name
    class_attribute :reports_progress, default: false
    self.parameters = parameters.to_a + [:user_job_result_id]
  end

  def enqueue!
    # @user_id is set in #initialize of ExportBaseJob
    # Additionally an attr writer is provided so it can be set e.g. when enqueueing a job
    # from another job
    # For jobs that are not export jobs, we fall back to Auth.current_person,
    # which is the currently logged in or imitated user
    enqueueing_person = Person.find_by(id: @user_id) || Auth.current_person

    return super unless enqueueing_person

    ActiveRecord::Base.transaction do
      user_job_result = UserJobResult.create!(
        person: enqueueing_person, job_name:, reports_progress:,
        filename: @options&.dig(:filename), filetype: @format,
        max_attempts: try(:max_attempts)
      )
      @user_job_result_id = user_job_result.id

      delayed_job = super
      user_job_result.update!(delayed_job:)

      delayed_job
    end
  end

  def before(delayed_job)
    user_job_result.report_in_progress! if @user_job_result_id
    super if defined?(super)
  end

  def success(delayed_job)
    user_job_result.report_success!(delayed_job.attempts + 1) if @user_job_result_id
    super if defined?(super)
  end

  def error(delayed_job, exception, payload = parameters)
    user_job_result.report_error!(delayed_job.attempts + 1) if @user_job_result_id
    super if defined?(super)
  end

  def failure(delayed_job)
    user_job_result.report_failure! if @user_job_result_id
    super if defined?(super)
  end

  def report_progress!(current_iteration, iteration_count)
    return unless @user_job_result_id

    user_job_result.report_progress!(current_iteration, iteration_count)
  end

  def user_job_result
    @user_job_result ||= UserJobResult.find(@user_job_result_id)
  end
end
