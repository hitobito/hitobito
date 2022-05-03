# frozen_string_literal: true

module Messages
  module BulkMail
    class Delivery
      class RetriesExceeded < StandardError; end

      INVALID_EMAIL_ERRORS = [
        'Domain not found',
        'Recipient address rejected',
        'Bad sender address syntax'
      ].freeze

      attr_reader :succeeded, :failed

      def initialize(mail_factory, emails, retries)
        @mail_factory = mail_factory
        @emails = emails
        @retries = retries
      end

      def deliver
        @failed = retried_delivery(@mail_factory, @emails, @retries)
        @succeeded = @emails - @failed
      end

      private

      def retried_delivery(mail_factory, emails, retries_left)
        raise RetriesExceeded if retries_left == 0

        failed = try_to_send_mail(mail_factory, emails)

        if failed.empty?
          []
        else
          failed + retried_delivery(mail_factory, emails - failed, retries_left - 1)
        end
      end

      def try_to_send_mail(mail_factory, recipient_emails)
        mail_factory.to(recipient_emails).deliver
        []
      rescue => error
        if invalid_email?(error)
          invalid_emails(error, recipient_emails)
        else
          # We might want to retry again in this case instead,
          # but let's find out which exception class to catch
          # and not just catch anything
          raise error
        end
      end

      def invalid_email?(error)
        INVALID_EMAIL_ERRORS.any? { |msg| error.message =~ Regexp.new(msg) }
      end

      def invalid_emails(error, emails)
        invalid = emails.select { |email| error.message.include?(email) }

        # If we cannot extract email from error message, raise
        raise error if invalid.empty?

        invalid
      end
    end
  end
end
