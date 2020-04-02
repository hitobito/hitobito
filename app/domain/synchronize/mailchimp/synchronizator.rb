#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'digest/md5'

module Synchronize
  module Mailchimp
    class Synchronizator
      attr_reader :list, :result

      class_attribute :merge_fields, :member_fields
      self.member_fields = []

      self.merge_fields = [
        [ 'Gender', 'dropdown', { choices: %w(m w) },  ->(p) { p.gender } ]
      ]

      def initialize(mailing_list)
        @list = mailing_list
        @result = Result.new
      end

      def perform
        create_segments
        create_merge_fields

        subscribe_members
        unsubscribe_members

        update_segments
        update_members

        destroy_segments
      end

      def missing_people
        people.reject do |person|
          members_by_email.keys.include?(person.email) || person.email.blank?
        end
      end

      def obsolete_emails
        members_by_email.keys - people.collect(&:email)
      end

      def missing_segments
        tags.keys - client.fetch_segments.collect { |s| s[:name] }
      end

      def obsolete_segment_ids
        client.fetch_segments.reject { |s| tags.key?(s[:name]) }.collect { |s| s[:id] }
      end

      def missing_merge_fields
        labels = client.fetch_merge_fields.collect { |field| field[:tag] }
         merge_fields.reject { |name, _, _| labels.include?(name.upcase) }
      end

      def stale_segments
        segments = client.fetch_segments.index_by { |t| t[:name] }

        tags.collect do |tag, emails|
          next if emails.sort == remote_tags.fetch(tag, []).sort
          next unless segments.key?(tag)

          [segments.dig(tag, :id), emails]
        end.compact
      end

      def changed_people
        @changed_people ||= people.select do |person|
          member = members_by_email[person.email]
          member.deep_merge(client.subscriber_body(person)) != member if member
        end
      end

      def client
        @client ||= Client.new(list, member_fields: member_fields, merge_fields: merge_fields)
      end

      private

      def subscribe_members
        result.track(:subscribe_members, client.subscribe_members(missing_people))
      end

      def unsubscribe_members
        result.track(:unsubscribe_obsolete_members, client.unsubscribe_members(obsolete_emails))
      end

      def update_segments
        result.track(:update_segments, client.update_segments(stale_segments))
      end

      def update_members
        result.track(:update_members, client.update_members(changed_people)) if changed_people.present?
      end

      def create_merge_fields
        result.track(:create_merge_fields, client.create_merge_fields(missing_merge_fields))
      end

      def create_segments
        result.track(:create_segments, client.create_segments(missing_segments))
      end

      def destroy_segments
        result.track(:delete_segments, client.delete_segments(obsolete_segment_ids))
      end

      def tags
        @tags ||= people.each_with_object({}) do |person, hash|
          next unless person.email

          person.tags.each do |tag|
            value = tag.name
            hash[value] ||= []
            hash[value] << person.email
          end
        end
      end

      def remote_tags
        @remote_tags ||= members.each_with_object({}) do |member, hash|
          member[:tags].each do |tag|
            hash[tag[:name]] ||= []
            hash[tag[:name]] << member[:email_address]
          end
        end
      end

      def members
        @members ||= client.fetch_members
      end

      def members_by_email
        @members_by_email ||= members.index_by { |m| m[:email_address] }
      end

      def people
        @people ||= list.people.includes(:tags).unscope(:select)
      end

    end
  end
end
