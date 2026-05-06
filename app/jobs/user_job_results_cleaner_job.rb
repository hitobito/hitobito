# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class UserJobResultsCleanerJob < RecurringJob
  run_every 1.day

  def perform_internal
    clean_up_user_job_results
  end

  private

  def clean_up_user_job_results
    UserJobResult.left_joins(:delayed_job).where(orphaned).or(older_than_a_day).find_each(&:destroy)
  end

  def orphaned
    <<~SQL.squish
      (user_job_results.delayed_job_id IS NULL)
      OR
      (
        user_job_results.end_timestamp IS NULL
        AND (delayed_jobs.id IS NULL OR delayed_jobs.failed_at IS NOT NULL)
      )
    SQL
  end

  def older_than_a_day
    UserJobResult.where("end_timestamp < :yesterday", yesterday: 1.day.ago)
  end
end
