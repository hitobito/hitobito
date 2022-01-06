# frozen_string_literal: true

module Messages
    module BulkMail
      class MailFactory
        # @param [Message] message
        def initialize(message)
          @message = message
        end

        # @param [[String]] receivers Receiver E-Mails
        # @return [Mail::Message]
        def to(receivers)
          raise "Implement me"
        end
      end
    end
  end
