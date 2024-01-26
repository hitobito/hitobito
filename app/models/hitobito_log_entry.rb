# frozen_string_literal: true

# == Schema Information
#
# Table name: hitobito_log_entries
#
#  id           :bigint           not null, primary key
#  category     :integer          not null
#  level        :integer          not null
#  message      :text(65535)      not null
#  subject_type :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  subject_id   :bigint
#
# Indexes
#
#  index_hitobito_log_entries_on_category  (category)
#  index_hitobito_log_entries_on_level     (level)
#  index_hitobito_log_entries_on_subject   (subject_type,subject_id)
#

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class HitobitoLogEntry < ApplicationRecord
  class_attribute :categories, default: %w[webhook ebics mail]

  enum level: %w[debug info warn error],
       _prefix: true

  validates_by_schema
  validates :category, presence: true, inclusion: { in: ->(_) { categories } }

  belongs_to :subject, polymorphic: true
end
