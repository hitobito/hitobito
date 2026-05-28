# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JobObservationsCleanerJob < RecurringJob
  run_every 1.day

  def perform_internal
    clean_up_job_observations
  end

  private

  def clean_up_job_observations
    base = JobObservation.left_joins(:delayed_job)

    # Remove records where job has completed more than one day ago
    old_records = base.where(finished_at: ..1.day.ago)

    # Remove records without an associated delayed job
    no_job_id = base.where(delayed_job_id: nil)

    # Remove records where job is uncompleted and delayed job id doesnt point to a record
    incomplete_missing_job = base.where(finished_at: nil, delayed_jobs: {id: nil})

    # Remove records where job is uncompleted but associated delayed job has failed
    incomplete_failed_job =
      base.where(finished_at: nil).where.not(delayed_jobs: {failed_at: nil})

    old_records
      .or(no_job_id)
      .or(incomplete_missing_job)
      .or(incomplete_failed_job)
      .find_each(&:destroy!)
  end
end
