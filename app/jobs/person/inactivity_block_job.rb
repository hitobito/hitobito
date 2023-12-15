# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
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
          .where(Person.arel_table[:last_sign_in_at].lt(block_after&.ago))
  end
end
