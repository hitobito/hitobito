# frozen_string_literal: true

#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "digest/md5"

module Synchronize
  module Mailchimp
    class Synchronizator
      attr_reader :list, :result

      class_attribute :merge_fields, :member_fields
      self.member_fields = []

      self.merge_fields = [
        ["Gender", "dropdown", {choices: %w[m w]}, ->(p) { p.gender }]
      ]

      DEFAULT_TAG = "hitobito-mailing-list-%d"

      def initialize(mailing_list, with_default_tag: true)
        @list = mailing_list
        @result = Result.new
        @default_tag = format(DEFAULT_TAG, @list.id) if with_default_tag
      end

      def perform
        execute(:create_segments, missing_segments)
        execute(:create_merge_fields, missing_merge_fields)

        execute(:subscribe_members, missing_subscribers)
        execute(:unsubscribe_members, obsolete_emails)

        execute(:update_segments, stale_segments)
        execute(:update_members, changed_subscribers)

        execute(:delete_segments, obsolete_segment_ids)

        tag_cleaned_members
        update_forgotten_emails
      end

      private

      def execute(operation, data)
        payload, response = client.send(operation, data)
        result.track(operation, payload, response) if payload
      end

      def update_forgotten_emails
        list.update!(mailchimp_forgotten_emails: (list.mailchimp_forgotten_emails + result.forgotten_emails).uniq)
      end

      def tag_cleaned_members
        emails = cleaned_members.pluck(:email_address)
        InvalidSubscriberTagger.new(emails, list).tag!
      end

      def missing_subscribers
        subscribers.reject { |subscriber| ignore?(subscriber.email) }
      end

      def obsolete_emails
        (managed_members - cleaned_members).pluck(:email_address) - subscribers.collect(&:email)
      end

      def missing_segments
        tags.keys - client.fetch_segments.pluck(:name)
      end

      def obsolete_segment_ids
        client.fetch_segments.reject { |s| tags.key?(s[:name]) }.pluck(:id)
      end

      def missing_merge_fields
        labels = client.fetch_merge_fields.pluck(:tag)
        merge_fields.reject { |name, _, _| labels.include?(name.upcase) }
      end

      def stale_segments
        segments_by_tag_name = client.fetch_segments.index_by { |t| t[:name] }

        tags.collect do |tag, emails|
          tag_id = segments_by_tag_name.dig(tag, :id)
          remote_emails = remote_tags.fetch(tag, []).sort
          local_emails = (emails - unsubscribed_members.pluck(:email_address) - list.mailchimp_forgotten_emails).sort

          SegmentUpdate.new(tag_id, local_emails, remote_emails, obsolete_emails).prepare
        end.compact.flatten(1)
      end

      def changed_subscribers
        @changed_subscribers ||= subscribers.select do |subscriber|
          member = members_by_email[subscriber.email]
          member.deep_merge(client.subscriber_body(subscriber)) != member if member
        end
      end

      def client
        @client ||= Client.new(list, member_fields: member_fields, merge_fields: merge_fields)
      end

      def remote_tags
        @remote_tags ||= members.each_with_object({}) do |member, hash|
          member[:tags].each do |tag|
            hash[tag[:name]] ||= []
            hash[tag[:name]] << member[:email_address]
          end
        end
      end

      def segments
        @segments ||= client.fetch_segments
      end

      def members
        @members ||= client.fetch_members
      end

      def managed_members
        return members if @default_tag.blank? || initial_default_tag_sync?

        members.select { |member| member[:tags].pluck(:name).include?(@default_tag) }
      end

      def unsubscribed_members
        @unsubscribed_members ||= members.select { |m| m[:status] == "unsubscribed" }
      end

      def cleaned_members
        @cleaned_members ||= members.select { |m| m[:status] == "cleaned" }
      end

      def members_by_email
        @members_by_email ||= members.index_by { |m| m[:email_address] }
      end

      def subscribers
        @subscribers ||= Subscriber.mailing_list_subscribers(list)
      end

      def ignore?(email)
        email.blank? || members_by_email.key?(email) ||
          list.mailchimp_forgotten_emails.include?(email)
      end

      def tags
        @tags ||= Subscriber
          .mailing_list_tags(list)
          .except(*PersonTags::Validation.tag_names).tap do |tags|
            tags[@default_tag] = subscribers.map(&:email).uniq.compact if @default_tag
          end
      end

      def initial_default_tag_sync?
        segments.pluck(:name).exclude?(@default_tag)
      end
    end
  end
end
