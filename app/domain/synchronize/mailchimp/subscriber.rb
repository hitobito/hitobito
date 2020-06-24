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
        mailing_list.people.map do |person|
          self.new(person, person.email)
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
        @email = email
      end

      # Delegate all other messages to person
      def method_missing(method_name, *args, &block)
        super unless person.respond_to?(method_name)

        person.send(method_name, *args, &block)
      end
    end
  end
end
