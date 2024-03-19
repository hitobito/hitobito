# frozen_string_literal: true

#  Copyright (c) 2023-2024, Schweizer Alpen Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: self_registration_reasons
#
#  id         :bigint           not null, primary key
#  text       :text(65535)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class SelfRegistrationReason < ApplicationRecord
  validates_by_schema

  has_many :people

  translates :text
  validates :text, presence: true

  def to_s
    text.inspect
  end
end
