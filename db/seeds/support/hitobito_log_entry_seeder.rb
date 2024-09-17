# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class HitobitoLogEntrySeeder

  def seed_log_entry
    created_at = Faker::Time.between(from: DateTime.now - 3.days, to: DateTime.now)
    entry = HitobitoLogEntry.seed(
      { message: Faker::Hacker.say_something_smart,
        created_at: created_at,
        updated_at: created_at,
        category: random_category,
        level: random_level,
        payload: {hello: Faker::Name.first_name}
      })

    randomize_attachment(entry.first)

    entry
  end

  private

  def random_category
    HitobitoLogEntry.categories.sample
  end

  def random_level
    HitobitoLogEntry.levels.keys.sample
  end

  def randomize_attachment(entry)
    if (1..10).to_a.sample == 1 # 10% chance
      entry.attachment.attach({ io: StringIO.new(random_attachment), filename: "log_attachment_#{entry.id}" })
    end
  end

  def random_attachment
    all_attachments.sample
  end

  def all_attachments
    @all_attachments ||= begin
                           Dir.glob(Rails.root.join("spec", "fixtures", "invoices", "*.xml").to_s).map do
                             Rails.root.join(_1).read
                           end
                         end
  end
end
