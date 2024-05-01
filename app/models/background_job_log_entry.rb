# frozen_string_literal: true

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: background_job_log_entries
#
#  id          :bigint           not null, primary key
#  attempt     :integer
#  finished_at :datetime
#  job_name    :string(255)      not null
#  payload     :json
#  runtime     :integer
#  started_at  :datetime
#  status      :string(255)
#  group_id    :bigint
#  job_id      :bigint           not null
#
# Indexes
#
#  index_background_job_log_entries_on_group_id            (group_id)
#  index_background_job_log_entries_on_job_id              (job_id)
#  index_background_job_log_entries_on_job_id_and_attempt  (job_id,attempt) UNIQUE
#  index_background_job_log_entries_on_job_name            (job_name)
#

class BackgroundJobLogEntry < ApplicationRecord
  validates_by_schema

  store :payload, coder: JSON
end
