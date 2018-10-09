require 'digest/md5'

module Synchronize
  module Mailchimp

    class Destroyer
      def initialize(mailchimp_list_id, mailchimp_api_key, people_to_be_deleted)
        @mailchimp_list_id = mailchimp_list_id
        @people_to_be_deleted = people_to_be_deleted
        @gibbon = Gibbon::Request.new(api_key: mailchimp_api_key)
      end

      def call
        delete_people_on_the_list
      end

      private

      def delete_people_on_the_list
        @gibbon.batches.create(body: {
          operations: deleting_operations
        })
      end

      def deleting_operations
        @people_to_be_deleted.map do |person|
          {
            method: "DELETE",
            path: "lists/#{@mailchimp_list_id}/members/#{subscriber_hash person.email}"
          }
        end
      end

      def subscriber_hash email
        Digest::MD5.hexdigest email.downcase
      end
    end
  end
end
