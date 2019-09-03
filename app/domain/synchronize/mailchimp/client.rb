
#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'digest/md5'

module Synchronize
  module Mailchimp
    class Client
      attr_reader :list_id, :count, :api

      def initialize(mailing_list, count = 50)
        @list_id = mailing_list.mailchimp_list_id
        @count   = count

        @api = Gibbon::Request.new(api_key: mailing_list.mailchimp_api_key)
      end

      def members
        fetch_members
      end

      def delete(emails)
        execute_batch(emails) do |email|
          delete_operation(email)
        end
      end

      def subscribe(people)
        execute_batch(people) do |person|
          subscribe_operation(person)
        end
      end

      def delete_operation(email)
        subscriber_id = Digest::MD5.hexdigest(email.downcase)
        {
          method: 'DELETE',
          path: "lists/#{list_id}/members/#{subscriber_id}"
        }
      end

      def subscribe_operation(person)
        {
          method: 'POST',
          path: "lists/#{list_id}/members",
          body: subscriber_body(person).to_json
        }
      end

      private

      def fetch_members(list = [], offset = 0)
        params = { count: count, offset: offset }

        body = api.lists(list_id).members.retrieve(params: params).body.to_h
        body['members'].each do |entry|
          list << entry.slice('email_address', 'status').symbolize_keys
        end

        next_offset = offset + count
        if body['total_items'] > next_offset
          fetch_members(list, next_offset)
        else
          list
        end
      end

      def execute_batch(list)
        operations = list.collect do |item|
          yield item
        end

        api.batches.create(body: { operations: operations })
      end

      def subscriber_body(person)
        {
          email_address: person.email,
          status: 'subscribed',
          merge_fields: {
            FNAME: person.first_name,
            LNAME: person.last_name
          }
        }
      end
    end
  end
end
