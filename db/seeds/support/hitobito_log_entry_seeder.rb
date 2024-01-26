# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class HitobitoLogEntrySeeder

  def seed_log_entry
    created_at = Faker::Time.between(from: DateTime.now - 3.days, to: DateTime.now)
    HitobitoLogEntry.seed(
      { message: Faker::Hacker.say_something_smart,
        created_at: created_at,
        updated_at: created_at,
        category: random_category,
        level: random_level,
        payload: {hello: Faker::Name.first_name}
      })
  end

  private

  def random_category
    HitobitoLogEntry.categories.sample
  end

  def random_level
    HitobitoLogEntry.levels.keys.sample
  end

end
