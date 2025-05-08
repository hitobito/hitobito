# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Bounce < ApplicationRecord
  BLOCK_THRESHOLD = 5

  before_validation :evaluate_blocking

  class << self
    def record(email, mailing_list_id: nil)
      bounce = find_or_create_by(email: email)
      if mailing_list_id.present?
        bounce.mailing_list_ids ||= []
        bounce.mailing_list_ids << mailing_list_id
      end
      bounce.increment(:bounce_count)

      bounce.save
    end
  end

  def person
    Person.find_by(email: email)
  end

  # block!
  # blocked?
  # record_for(mailing_list_id:)
  # mailing_lists

  private

  def evaluate_blocking
    if bounce_count >= BLOCK_THRESHOLD
      self.blocked_at = DateTime.current
    end
  end
end
