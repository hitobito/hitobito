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
    @person_id = @user_id || Auth.current_person&.id
    raise "User manageable jobs must be called from context with auth user" unless @person_id

    user_job_result = create_default_user_job_result
    @user_job_result_id = user_job_result.id

    delayed_job = super
    user_job_result.update!(delayed_job:)
    delayed_job
  end

  def before(delayed_job)
    user_job_result&.report_in_progress
    super
  end

  def success(job)
    user_job_result&.report_success(job.attempts + 1)
    super if defined?(super)
  end


  def error(job, exception, payload = parameters)
    user_job_result&.report_error(job.attempts + 1)
    super
  end

  def failure(job)
    user_job_result&.report_failure
    super if defined?(super)
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
  def report_progress(current_iteration, iteration_count)
    user_job_result&.report_progress(current_iteration, iteration_count)
  end

  def user_job_result
    @user_job_result ||= UserJobResult.find(@user_job_result_id)
  end

  private

  def create_default_user_job_result
    UserJobResult.create!(
      name: job_name,
      filetype: filetype,
      progress: default_progress,
      person_id: @person_id,
      status: "planned",
      start_timestamp: Time.now.to_i,
      attempts: 0,
      filename: filename_with_timestamp,
      reports_progress: reports_progress
    )
  end

  def filename_with_timestamp
    filename = @options&.dig(:filename)
    return unless filename

    "#{filename.to_s.parameterize(preserve_case: true)}_#{Time.now.to_i}.#{filetype}"
  end

  def filetype
    @format || :txt
  end

  def default_progress
    reports_progress ? 0 : nil
  end
end
