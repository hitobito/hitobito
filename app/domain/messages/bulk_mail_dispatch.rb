# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class BulkMailDispatch
    delegate :update, :success_count, to: '@message'

    def initialize(message)
      mailing_list = message.mailing_list

      @message = message
      @people = mailing_list.people
      @labels = mailing_list.labels
      @now = Time.current
    end

    def run
      if @message.message_recipients.exists?
        deliver_mails
      else
        init_recipient_entries
      end
    end

    private

    def deliver_mails
      # TODO: implement delivery
    end

    def init_recipient_entries
      recipients = []
      address_list.each do |address|
        recipient_attrs = { message_id: @message.id,
                            created_at: @now,
                            person_id: address[:person_id],
                            email: address[:email] }

        if valid?(address[:email])
          recipient_attrs.merge!(state: :pending)
          else
            recipient_attrs.merge!(state: :failed,
                                   error: "Invalid email")
        end

        recipients << recipient_attrs
      end

      MessageRecipient.insert_all(recipients)
    end

    def valid?(email)
      Truemail.valid?(email)
    end

    def address_list
      Messages::BulkMail::AddressList.new(@people, @labels).entries
    end
  end
end
