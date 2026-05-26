#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

module Synchronize
  module Mailchimp
    # Subscriber represents a single entry of our data that should be synchronized.
    # This entry always belongs to, but does not equal a Person: Depending on the mailing_list
    # configuration the Persons additional_emails should be synchronized as well, leading to
    # multiple Subscribers per Person.

    class Subscriber
      def self.mailing_list_subscribers(mailing_list)
        if mailing_list.mailchimp_include_additional_emails
          default_and_additional_addresses(mailing_list)
        else
          default_addresses(mailing_list)
        end
      end

      def self.recipients(mailing_list)
        if Settings.mailchimp.subscribe_managers
          people_ids = mailing_list.people.pluck(:id)
          Person.left_joins(:people_manageds).distinct
            .where(people_manageds: {managed_id: people_ids})
            .or(Person.distinct.where(id: people_ids))
        else
          mailing_list.people
        end
      end

      def self.default_and_additional_addresses(mailing_list)
        people = recipients(mailing_list)
        additional_emails = fetch_additional_emails(people)
        people.flat_map do |person|
          [new(person, person.email)] +
            additional_emails[person.id].map { |email| new(person, email) }
        end
      end

      def self.fetch_additional_emails(people)
        result = Hash.new { |h, k| h[k] = [] }
        AdditionalEmail.where(
          contactable_type: Person.sti_name,
          contactable_id: people.map(&:id),
          mailings: true
        ).pluck(:contactable_id, :email)
          .each { |(id, email)| result[id] << email }
        result
      end

      def self.default_addresses(mailing_list)
        recipients(mailing_list).map do |person|
          new(person, person.email)
        end
      end

      def self.mailing_list_tags(mailing_list)
        people = mailing_list.people.includes(:tags).unscope(:select)
        people.each_with_object({}) do |person, hash|
          next unless person.email

          person.tags.each do |tag|
            value = tag.name
            hash[value] ||= []
            hash[value] << person.email
          end
        end
      end

      attr_reader :person, :email

      def initialize(person, email)
        @person = person
        @email = email&.downcase
      end

      def primary?
        email == person.email
      end

      # Delegate all other messages to person
      def method_missing(method_name, *args, &block)
        super unless person.respond_to?(method_name)

        person.public_send(method_name, *args, &block)
      end

      def respond_to_missing?(method, *)
        person.respond_to?(method)
      end
    end
  end
end
