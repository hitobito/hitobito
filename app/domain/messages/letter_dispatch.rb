# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class LetterDispatch
    delegate :update!, :success_count, :send_to_households?, :salutation, to: '@message'

    def initialize(message, options = {})
      @message = message
      @options = options
      @now = Time.current
    end

    def run
      if send_to_households?
        create_for_households!
      else
        create_for_people!
      end

      DispatchResult.finished
    end

    private

    def people
      @people ||= @message.mailing_list.people.with_address.select(:household_key)
    end

    def reciept_attrs
      @receipt_attrs ||= { message_id: @message.id, created_at: @now }
    end

    def create_for_people!
      limit(people, @options[:recipient_limit]).find_in_batches do |batch|
        count = create_recipient_entries(batch)
        update!(success_count: count)
      end
    end

    def create_for_households!
      # In household exports, half of the preview should be normal, half households
      household_list = People::HouseholdList.new(limit(people, @options[:recipient_limit]&.div(2)))

      # first, run a separate batch for people that are grouped in households, because that's slower
      household_list.only_households_in_batches do |batch|
        create_recipient_entries(batch)
        update!(success_count: success_count + batch.size)
      end

      # batch run for people without household
      household_list.people_without_household_in_batches do |batch|
        count = create_recipient_entries(batch)
        update!(success_count: success_count + count)
      end
    end

    def create_recipient_entries(people_or_households_batch)
      rows = people_or_households_batch.collect do |person_or_household|
        collect_household(person_or_household) do |person, housemates|
          reciept_attrs.merge(
            person_id: person.id,
            address: address_for_letter(person, housemates),
            salutation: salutation_for_letter(person, housemates)
          )
        end
      end
      MessageRecipient.insert_all(rows.flatten)
      rows.size
    end

    def limit(scope, limit)
      limit.present? ? scope.limit(limit) : scope
    end

    def collect_household(person_or_household)
      housemates = Array.wrap(person_or_household).sort_by(&:last_name)

      housemates.collect do |person|
        yield person, housemates
      end
    end

    def address_for_letter(person, housemates)
      if send_to_households? && housemates.count > 1
        Person::Address.new(person).for_household_letter(housemates)
      else
        person.address_for_letter
      end
    end

    def salutation_for_letter(person, housemates)
      if send_to_households? && housemates.count > 1
        Salutation.new(person, salutation).value_for_household(housemates)
      else
        Salutation.new(person, salutation).value
      end
    end
  end
end
