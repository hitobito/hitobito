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

      if send_to_households? && @options[:recipient_limit]
        # In household exports, half of the preview should be normal, half households
        @options[:recipient_limit] /= 2
      end
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
        count = create_recipient_entries(batch)
        update!(success_count: count)
      end
    end

    def people_with_household_addresses
      household_list = People::HouseholdList.new(people)

      # first, run a separate batch for people that are grouped in households, because that's slower
      household_list.only_households.find_in_batches do |batch|
        household_keys = batch.map(&:key)
        household_members = @message.mailing_list.people
                                .select(:household_key)
                                .where(household_key: household_keys)
        create_recipient_entries(household_members)
        update!(success_count: success_count + batch.size)
      end

      # batch run for people without household
      household_list.people_without_household.with_address.find_in_batches do |batch|
        count = create_recipient_entries(batch)
        update!(success_count: success_count + count)
      end
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
      rows.size
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
      household_people = people.
          select { |p| p.household_key == person.household_key }.
          sort_by(&:last_name) # sort alphabetically
      if household_people.count > 1
        Person::Address.new(person).for_household_letter(household_people)
      end
    end
  end
end
