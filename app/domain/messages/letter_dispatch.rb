# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class LetterDispatch
    delegate :update, :success_count, to: '@message'

    def initialize(message, people)
      @message = message
      @people = people
      @now = Time.current
    end

    def run
      @people.find_in_batches do |batch|
        rows = batch.collect do |person|
          reciept_attrs.merge(
            person_id: person.id,
            address: person.address_for_letter
          )
        end
        MessageRecipient.insert_all(rows)
        update(success_count: success_count + rows.size)
      end
    end

    private

    def reciept_attrs
      { message_id: @message.id, created_at: @now }
    end
  end
end
