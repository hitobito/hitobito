# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class LetterDispatch
    delegate :update!, :success_count, to: '@message'

    # TODO why don't we fetch people from message's mailing list?
    def initialize(message, people)
      @message = message
      @people = people
      @now = Time.current
    end

    def run
      if @message.send_to_households?
        people_by_households
      else
        people_addresses
      end
    end

    private

    def reciept_attrs
      { message_id: @message.id, created_at: @now }
    end

    def people_addresses
      @people.with_address.find_in_batches do |batch|
        create_recipient_entries(batch)
      end
    end

    def people_by_households
      people_ids = @people.pluck(:id)
      household_list = People::HouseholdList.new(people_ids)

      # batch run for people without household
      household_list.people_without_household.with_address.find_in_batches do |batch|
        create_recipient_entries(batch)
      end

      # run sep. batch for people with household
      household_people = household_list.household_people.with_address
      create_recipient_entries(household_people)
    end

    def create_recipient_entries(people_batch)
      rows = people_batch.collect do |person|
        reciept_attrs.merge(
          person_id: person.id,
          address: person.address_for_letter
        )
      end
      MessageRecipient.insert_all(rows)
      update!(success_count: success_count + rows.size)
    end
  end
end
