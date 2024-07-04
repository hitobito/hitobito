# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: hitobito_log_entries
#
#  id           :bigint           not null, primary key
#  category     :string(255)      not null
#  level        :integer          not null
#  message      :text(65535)      not null
#  payload      :json
#  subject_type :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  subject_id   :bigint
#
# Indexes
#
#  index_hitobito_log_entries_on_level             (level)
#  index_hitobito_log_entries_on_multiple_columns  (category,level,subject_id,subject_type,message)
#  index_hitobito_log_entries_on_subject           (subject_type,subject_id)
#

class HitobitoLogEntry < ApplicationRecord
  class_attribute :categories, default: %w[webhook ebics mail]

  enum level: {"debug" => 0, "info" => 1, "warn" => 2, "error" => 3},
    _prefix: true

  validates_by_schema
  validates :category, presence: true, inclusion: {in: ->(_) { categories }}

  belongs_to :subject, polymorphic: true
end
