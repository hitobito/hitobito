# frozen_string_literal: true

#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Groups::ContactPersonCleanerJob < RecurringJob
  private

  def perform_internal
    member_types = Role.all_types.select(&:member?).collect(&:sti_name)

    Group.where.not(contact_id: nil).find_each do |group|
      next if Role.exists?(group_id: group.id, person_id: group.contact_id, type: member_types)

      group.update!(contact: nil)
      create_log_entry(group)
    end
  end

  def next_run
    # Sets next run to 04:00 of next day
    Time.zone.tomorrow.at_beginning_of_day.change(hour: 4).in_time_zone
  end

  def create_log_entry(group)
    HitobitoLogEntry.create!(
      level: :info,
      message: "Contact person of #{group.name} was removed, due to person not having any active member role in #{group.name}",
      category: :cleanup,
      subject: group
    )
  end
end
