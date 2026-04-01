#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module UserManageableJob
  extend ActiveSupport::Concern
  delegate :report_progress, to: :@user_job_result

  prepended do
    class_attribute :job_name, default: name
    class_attribute :reports_progress, default: false
    self.parameters = parameters.to_a + [:user_job_result_id]
  end

  def enqueue!
    person_id = @user_id || Auth.current_person&.id
    raise "User manageable jobs must be called from context with auth user" unless person_id

    user_job_result = UserJobResult.create_default!(
      person_id, job_name, @options&.dig(:filename), @format, reports_progress
    )
    @user_job_result_id = user_job_result.id

    delayed_job = super
    user_job_result.update!(delayed_job:)
    delayed_job
  end

  def before(delayed_job)
    user_job_result.report_in_progress
    super
  end

  def success(job)
    user_job_result.report_success(job.attempts + 1)
    super if defined?(super)
  end

  def error(job, exception, payload = parameters)
    user_job_result.report_error(job.attempts + 1)
    super
  end

  def failure(job)
    user_job_result.report_failure
    super if defined?(super)
  end

  def user_job_result
    @user_job_result ||= UserJobResult.find(@user_job_result_id)
  end
end
