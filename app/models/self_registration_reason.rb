# frozen_string_literal: true

# == Schema Information
#
# Table name: self_registration_reasons
#
#  id         :bigint           not null, primary key
#  text       :text(65535)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistrationReason < ApplicationRecord
  validates_by_schema

  has_many :people

  translates :text
  validates :text, presence: true

  def to_s
    text.inspect
  end
end
