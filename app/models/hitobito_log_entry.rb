# frozen_string_literal: true

# == Schema Information
#
# Table name: hitobito_log_entries
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  category     :integer          not null
#  level        :integer          not null
#  message      :text(65535)      not null
#  subject_type :string(255)
#  subject_id   :bigint
#

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class HitobitoLogEntry < ApplicationRecord
  enum category: %w[webhook ebics mail],
       level: %w[debug info warn error],
       _prefix: true

  validates_by_schema
  validates :category, presence: true # maybe obsolete after validates_by_schema upgrade

  belongs_to :subject, polymorphic: true
end
