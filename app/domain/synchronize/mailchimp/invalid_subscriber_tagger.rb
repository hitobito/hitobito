# frozen_string_literal: true

#
#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Synchronize
  module Mailchimp
    class InvalidSubscriberTagger
      attr_reader :emails, :list

      def initialize(emails, list)
        @emails = emails
        @list = list
      end

      def tag!
        emails.each do |email|
          subscriber = subscribers[email]
          next unless subscriber

          kind = subscriber.primary? ? :primary : :additional
          Contactable::InvalidEmailTagger.new(subscriber.person, email, kind).tag!
        end
      end

      def subscribers
        @subscribers ||= Synchronize::Mailchimp::Subscriber
          .mailing_list_subscribers(list).index_by(&:email)
      end
    end
  end
end
