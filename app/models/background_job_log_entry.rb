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
#  job_id      :bigint           not null
#  job_name    :string(255)      not null
#  group_id    :bigint
#  started_at  :datetime
#  finished_at :datetime
#  runtime     :integer
#  attempt     :integer
#  status      :string(255)
#  payload     :text(4294967295)
#  created_at  :datetime         default(NULL), not null
#  updated_at  :datetime         default(NULL), not null
#

class BackgroundJobLogEntry < ApplicationRecord
  validates_by_schema

  store :payload, coder: JSON
end
