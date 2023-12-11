# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::InactivityBlockWarningJob < RecurringJob
  def perform
    return unless Person::BlockService.warn?

    warn_scope.find_each { |person| Person::BlockService.new(person).inactivity_warning! }
    true
  end

  def warn_scope
    Person.where.not(last_sign_in_at: nil)
          .where(Person.arel_table[:last_sign_in_at].lt(Person::BlockService.warn_after&.ago))
          .where(inactivity_block_warning_sent_at: nil, blocked_at: nil)
  end
end
