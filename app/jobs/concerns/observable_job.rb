#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ObservableJob
  extend ActiveSupport::Concern

  prepended do
    attr_writer :user_id
    class_attribute :reports_progress, default: false
    self.parameters = parameters.to_a + [:job_observation_id]
  end

  def enqueue!(options = {})
    # @user_id is set in #initialize of ExportBaseJob
    # Additionally an attr writer is provided so it can be set e.g. when enqueueing a job
    # from another job. We check if the instance variable is defined so it can be explicitly
    # set to nil without falling back to the currently authenticated person
    # For jobs that are not export jobs, we fall back to Auth.current_person,
    # which is the currently logged in or imitated user
    enqueueing_person = defined?(@user_id) ? Person.find_by(id: @user_id) : Auth.current_person

    return super unless enqueueing_person

    ActiveRecord::Base.transaction do
      job_observation = JobObservation.create!(
        person: enqueueing_person, job_class: self.class.name,
        reports_progress:, filename: @options&.dig(:filename),
        filetype: @format, max_attempts: try(:max_attempts)
      )
      @job_observation_id = job_observation.id

      delayed_job = super
      job_observation.update!(delayed_job:)

      delayed_job
    end
  end

  def before(delayed_job)
    job_observation.report_in_progress! if @job_observation_id
    super if defined?(super)
  end

  def success(delayed_job)
    job_observation.report_success!(delayed_job.attempts + 1) if @job_observation_id
    super if defined?(super)
  end

  def error(delayed_job, exception, payload = parameters)
    job_observation.report_error!(delayed_job.attempts + 1) if @job_observation_id
    super if defined?(super)
  end

  def failure(delayed_job)
    job_observation.report_failure! if @job_observation_id
    super if defined?(super)
  end

  def report_progress!(current_iteration, iteration_count)
    return unless @job_observation_id

    job_observation.report_progress!(current_iteration, iteration_count)
  end

  def job_observation
    @job_observation ||= JobObservation.find(@job_observation_id)
  end
end
