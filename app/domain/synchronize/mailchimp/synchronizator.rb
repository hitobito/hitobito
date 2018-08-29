require 'digest/md5'

module Synchronize
  module Mailchimp

    class Synchronizator
      def initialize(mailing_list)
        @mailing_list = mailing_list
        @gibbon = Gibbon::Request.new(api_key: @mailing_list.mailchimp_api_key)
        @people_on_the_list = @mailing_list.people
        @people_on_the_mailchimp_list = @gibbon.lists(@mailing_list.mailchimp_list_id).members.retrieve.body["members"]
      end

      def call
        subscribe_people_on_the_list
        delete_people_not_on_the_list
      end

      private

      def subscribe_people_on_the_list
        @gibbon.batches.create(body: {
          operations: subscribing_operations
        })
      end

      def delete_people_not_on_the_list
        @gibbon.batches.create(body: {
          operations: deleting_operations
        })
      end

      def subscribing_operations
        people_to_be_subscribed.map do |person|
          {
            method: "POST",
            path: "lists/#{@mailing_list.mailchimp_list_id}/members",
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

      def deleting_operations
        people_to_be_deleted.map do |person|
          {
            method: "DELETE",
            path: "lists/#{@mailing_list.mailchimp_list_id}/members/#{subscriber_hash person["email_address"]}"
          }
        end
      end

      def people_to_be_subscribed
        @people_on_the_list.reject do |person|
          @people_on_the_mailchimp_list.map{|p| p["email_address"]}.include? person.email
        end
      end

      def people_to_be_deleted
        @people_on_the_mailchimp_list.reject do |subscriber|
          @people_on_the_list.map(&:email).include? subscriber["email_address"]
        end
      end

      def subscriber_hash email
        Digest::MD5.hexdigest email.downcase
      end

    end
  end
end
