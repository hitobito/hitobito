# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Message < ActiveRecord::Base
  belongs_to :recipients_source, polymorphic: true
  has_many :message_recipients

  scope :list, -> { order(:updated_at) }

  ### CLASS METHODS

  class << self
    def in_year(year)
      year = Time.zone.today.year if year.to_i <= 0
      start_at = Time.zone.parse "#{year}-01-01"
      finish_at = start_at + 1.year
      where(updated_at: [start_at...finish_at])
    end
  end
end
