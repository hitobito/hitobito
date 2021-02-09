# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class TextMessageDispatch
    delegate :update, :success_count, to: '@message'

    def initialize(message, people)
      @message = message
      @people = people
      @now = Time.current
    end

    def run
      init_recipient_entries
      if send_text_message!
        sleep 15 unless Rails.env.test? # give it some time to deliver messages
        process_delivery_reports
      end
      update_message_status
    end

    private

    def provider_config
      s = group.settings(:text_message_provider)
      s.originator = group.name if s.originator.blank?
      s
    end

    def group
      @group ||= @message.mailing_list.group
    end

    def init_recipient_entries
      return if @message.message_recipients.present?

      recipient_numbers.find_in_batches do |batch|
        rows = batch.collect do |phone_nr|
          reciept_attrs(phone_nr, :pending)
        end
        MessageRecipient.insert_all(rows)
      end
    end

    def person_ids
      @people.collect(&:id)
    end

    def recipient_numbers
      PhoneNumber.where(label: 'Mobil', # get from settings
                        contactable_type: Person.sti_name,
                        contactable_id: person_ids)
    end

    def reciept_attrs(phone_nr, state)
      { message_id: @message.id,
        created_at: @now,
        person_id: phone_nr.contactable_id,
        phone_number: phone_nr.number,
        state: state }
    end

    def update_message_status
      failed_count = recipients(state: 'failed').count
      success_count = recipients(state: 'sent').count
      state = success_count.eql?(0) && failed_count.positive? ? 'failed' : 'finished'
      @message.update!(success_count: success_count, failed_count: failed_count, state: state)
    end

    def send_text_message!
      recipients(state: 'pending')
        .find_in_batches(batch_size: Messages::TextMessageProvider::Base::MAX_RECIPIENTS) do |rps|
          update_recipients(rps, state: 'sending')
          send_status = client.send(text: @message.text, recipients: recipients_list(rps))
          if not_ok?(send_status)
            abort_dispatch(send_status, rps)
            return false
          end
        end
      true
    end

    def update_recipients(recipient_list, attrs = {})
      r_ids = recipient_list.collect(&:id)
      @message.message_recipients.where(id: r_ids).update_all(attrs)
    end

    def abort_dispatch(status, recipient_list)
      update_recipients(recipient_list, state: 'failed', error: status[:message])
    end

    def recipients_list(recipients)
      recipients.collect do |r|
        "#{r.phone_number}:#{r.id}"
      end
    end

    def recipients(state:)
      recipients = @message.message_recipients
      recipients.where(state: state)
    end

    def process_delivery_reports
      recipients = @message.message_recipients.reload
      recipient_ids = recipients.collect(&:id)
      report = client.delivery_reports(recipient_ids: recipient_ids)
      if not_ok?(report)
        abort_dispatch(report, recipients)
      else
        recipients.each do |r|
          update_recipient(report[:delivery_reports], r)
        end
      end
    end

    def update_recipient(delivery_reports, recipient)
      report = delivery_reports[recipient.id.to_s]
      error = 'unkown'
      if report
        if report[:status].eql?(:ok)
          state = 'sent'
          error = nil
        else
          error = report[:status_message]
        end
      end
      recipient.update!(state: state || 'failed', error: error)
    end

    def client
      @client ||= Messages::TextMessageProvider::Base.init(config: provider_config)
    end

    def not_ok?(status)
      !status[:status].eql?(:ok)
    end
  end
end
