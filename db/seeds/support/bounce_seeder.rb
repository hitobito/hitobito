# frozen_string_literal: true

# Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class BounceSeeder
  def seed_one
    created_at = Faker::Time.between(from: DateTime.now - 14.days, to: DateTime.now - 3.days)

    bounce_count = Faker::Number.between(from: 1, to: 10)
    email = Faker::Internet.email(domain: 'example.net')
    blocked_count = bounce_count > Bounce::BLOCK_THRESHOLD ? 1 : 0
    blocked_at = blocked_count.positive? ? created_at.advance(day: 1).to_date : nil
    mailing_list_ids = []

    updated_at = [blocked_at, created_at].compact.max

    Bounce.seed({
      email:,
      bounce_count:,
      blocked_count:,
      blocked_at:,
      mailing_list_ids:,
      created_at:
    }).first
  end
end
