require 'digest/md5'

module Synchronize
  module Mailchimp

    def self.synchronize(mailing_list_id)
      MailchimpSynchronizator.new(mailing_list_id).call
    end

    class MailchimpSynchronizator
      def initialize(mailing_list_id)
        @mailing_list = MailingList.find(mailing_list_id)
        @gibbon = Gibbon::Request.new(api_key: mailing_list.mailchimp_api_key)
        @people_on_the_list = mailing_list.people
        @people_on_the_mailchimp_list = @gibbon.lists(@list_id).members.retrieve.body["members"]
      end

      def call
        subscribe_people_on_the_list
        unsubscribe_people_not_on_the_list
      end

      private

      def subscribe_people_on_the_list
        @gibbon.batches.create(body: {
          operations: subscribing_operations
        })
      end

      def unsubscribe_people_not_on_the_list
        @gibbon.batches.create(body: {
          operations: unsubscribing_operations
        })
      end

      def subscribing_operations
        people_to_be_subscribed.map do |person|
          {
            method: "POST",
            path: "lists/#{@list_id}/members",
            body: {
              email_address: person.email,
              status: "subscribed",
              merge_fields: {
                FNAME: person.first_name,
                LNAME: person.last_name
              }
            }.to_json
          }
        end
      end

      def unsubscribing_operations
        people_to_be_unsubscribed.map do |person|
          {
            method: "DELETE",
            path: "lists/#{@list_id}/members/#{subscriber_hash person["email_address"]}",
          }
        end
      end

      def people_to_be_subscribed
        @people_on_the_list.select do |person|
          !existing_subscribers_email_addresses.include? person.email
        end
      end

      def people_to_be_unsubscribed
        @people_on_the_mailchimp_list.select do |subscriber|
          !@people_on_the_list.map(&:email).include? subscriber["email_address"]
        end
      end

      def existing_subscribers_email_addresses
        @existing_subscribers.map{|subscriber| subscriber["email_address"]}
      end

      def subscriber_hash email
        Digest::MD5.hexdigest email.downcase
      end

    end
  end
end
