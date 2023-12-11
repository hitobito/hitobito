# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::InactivityBlockJob < RecurringJob
  def perform
    return unless Person::BlockService.block?

    block_scope.find_each { |person| Person::BlockService.new(person).block! }
    true
  end

  def block_scope(block_after = Person::BlockService.block_after)
    Person.where.not(last_sign_in_at: nil)
          .where(blocked_at: nil)
          .where(Person.arel_table[:inactivity_block_warning_sent_at]
                       .lt(block_after&.ago))
          .where(Person.arel_table[:last_sign_in_at]
                       .lt(Person.arel_table[:inactivity_block_warning_sent_at]))
  end
end
