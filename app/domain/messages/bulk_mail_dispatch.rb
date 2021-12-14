# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class BulkMailDispatch
    delegate :update, :success_count, to: '@message'

    def initialize(message)
      @message = message
      @people = message.mailing_list.people
      @now = Time.current
    end

    def run
      init_recipient_entries
    end

    private

    def group
      @group ||= @message.mailing_list.group
    end

    def init_recipient_entries
      return if @message.message_recipients.present?

      emails.find_in_batches do |batch|
        rows = batch.collect do |person|
          recipient_attrs(person.id, person.email, :pending)
        end
        MessageRecipient.insert_all(rows)
      end
    end

    def person_ids
      @people.collect(&:id)
    end

    def recipient_emails

    end

    def recipient_attrs(person_id, email, state)
      { message_id: @message.id,
        created_at: @now,
        person_id: person_id,
        email: email,
        state: state }
    end

    def emails
      # TODO: get person emails aswell as additional emails
    end

    def recipients(state:)
      recipients = @message.message_recipients
      recipients.where(state: state)
    end
  end
end
