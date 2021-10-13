# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class LetterDispatch
    delegate :update!, :success_count, :send_to_households?, to: '@message'

    def initialize(message, options = {})
      @message = message
      @options = options
      @now = Time.current
    end

    def run
      if send_to_households?
        people_with_household_addresses
      else
        people_addresses
      end
    end

    private

    def people
      @people ||= fetch_people
    end

    def fetch_people
      recipient_limit = @options[:recipient_limit]
      people = @message.mailing_list.people
      if recipient_limit
        people = people.limit(recipient_limit)
      end
      people
    end

    def reciept_attrs
      { message_id: @message.id, created_at: @now }
    end

    def people_addresses
      people.with_address.find_in_batches do |batch|
        create_recipient_entries(batch)
      end
    end

    def people_with_household_addresses
      household_list = People::HouseholdList.new(people)

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
        address, household = address_for_letter(person, people_batch)
        reciept_attrs.merge(
          person_id: person.id,
          address: address,
          household_address: household
        )
      end
      MessageRecipient.insert_all(rows)
      update!(success_count: success_count + rows.size)
    end

    def address_for_letter(person, people)
      address = person.address_for_letter
      household = false

      if send_to_households? && person.household_key?
        household_addr = household_address(person, people)
        if household_addr.present?
          address = household_addr
          household = true
        end
      end
      [address, household]
    end

    def household_address(person, people)
      household_people = people.select { |p| p.household_key == person.household_key }
      if household_people.count > 1
        names = household_people.collect { |p| p.full_name }
        Person::Address.new(person).for_household_letter(names)
      end
    end
  end
end
