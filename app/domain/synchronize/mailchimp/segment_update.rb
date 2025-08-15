# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Synchronize
  module Mailchimp
    class SegmentUpdate
      attr_reader :tag_id, :emails_to_add, :emails_to_remove

      SLICE_SIZE = 500

      def initialize(tag_id, local_emails, remote_emails, obsolete_emails)
        @tag_id = tag_id
        @emails_to_add = local_emails - remote_emails - obsolete_emails
        @emails_to_remove = remote_emails - local_emails - obsolete_emails
      end

      # Prepares the data for updating Mailchimp segments by grouping emails to add and remove.
      # rubocop:todo Layout/LineLength
      # Returns an array of tuples, each containing the tag_id and a hash with members to add and remove.
      # rubocop:enable Layout/LineLength
      # Emails are grouped in slices of SLICE_SIZE.
      #
      # Example return value:
      #   [
      # rubocop:todo Layout/LineLength
      #     [123, {members_to_add: ["add1@example.com", "add2@example.com"], members_to_remove: ["del1@example.com"]}],
      # rubocop:enable Layout/LineLength
      #     [123, {members_to_add: ["add3@example.com"], members_to_remove: []}]
      #   ]
      #
      def prepare
        return if stale?

        [emails_to_add_groups, emails_to_remove_groups].max_by(&:size).map.with_index do |_, index|
          members_to_add = Array(emails_to_add_groups[index])
          members_to_remove = Array(emails_to_remove_groups[index])
          [tag_id, {members_to_add:, members_to_remove:}]
        end
      end

      private

      def stale? = !(tag_id.present? && [emails_to_add, emails_to_remove].any?(&:present?))

      def emails_to_add_groups = @emails_to_add_groups ||= in_groups(emails_to_add)

      def emails_to_remove_groups = @emails_to_remove_groups ||= in_groups(emails_to_remove)

      def in_groups(list) = list.in_groups_of(SLICE_SIZE).map(&:compact).presence || [[]]
    end
  end
end
