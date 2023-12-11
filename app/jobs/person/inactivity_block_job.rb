# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::InactivityBlockJob < RecurringJob
  def perform
    period = Settings.inactivity_block&.block_after&.to_i
    return if period.blank? || period.zero?

    block_scope(period.seconds.ago).find_each do |person|
      Person::BlockService.new(person).block!
    end
    true
  end

  def block_scope(since)
    Person.where.not(last_sign_in_at: nil)
          .where(blocked_at: nil)
          .where(Person.arel_table[:last_sign_in_at].lt(since))
          .where(Person.arel_table[:inactivity_block_warning_sent_at].lt(since))
  end
end
