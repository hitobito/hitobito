# frozen_string_literal: true

module Messages
  module BulkMail
    class CreateRecipients
      def create!(message)
        mailing_list = message.mailing_list
        create_recipients(
          message,
          mailing_list.people,
          mailing_list.labels
        )
      end

      private

      def create_recipients(message, people, labels)
        recipients = recipient_attrs(message, people, labels)

        subject = "for message #{message.id}"
        if recipients.empty?
          Rails.logger.info("No recipients found #{subject}")
        else
          MessageRecipient.insert_all(recipients)
          Rails.logger.info("Inserted #{recipients.count} MessageRecipients #{subject}")
        end
      end

      def recipient_attrs(message, people, labels)
        created_at = Time.current
        addresses(people, labels).map do |address|
          { message_id: message.id,
            created_at: created_at,
            person_id: address[:person_id],
            email: address[:email] }
            .merge(state_attrs(address[:email]))
        end
      end

      def state_attrs(email)
        if valid?(email)
          { state: :pending }
        else
          { state: :failed, error: 'Invalid email' }
        end
      end

      def valid?(email)
        Truemail.valid?(email)
      end

      def addresses(people, labels)
        Messages::BulkMail::AddressList.new(people, labels).entries
      end
    end
  end
end
