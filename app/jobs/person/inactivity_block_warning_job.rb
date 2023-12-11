# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::InactivityBlockWarningJob < RecurringJob
  def perform
    period = Settings.inactivity_block&.warning_after&.to_i
    return if period.blank? || period.zero?

    warn_scope(period.seconds.ago).find_each do |person|
      Person::BlockService.new(person).inactivity_warning!
    end
    true
  end

  def warn_scope(since)
    Person.where.not(last_sign_in_at: nil)
          .where(Person.arel_table[:last_sign_in_at].lt(since))
          .where(inactivity_block_warning_sent_at: nil, blocked_at: nil)
  end
end
