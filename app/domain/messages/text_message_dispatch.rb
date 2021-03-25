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
        enqueue_delivery_reports!
      end
      @message.update_message_status!
    end

    private

    def enqueue_delivery_reports!
      job = TextMessageDeliveryReportJob.new(@message.id)
      Delayed::Job.enqueue(job, run_at: 15.seconds.from_now)
    end

    def provider_config
      group.settings(:text_message_provider).tap do |s|
        s.originator = group.name if s.originator.blank?
      end
    end

    def group
      @group ||= @message.mailing_list.group
    end

    def init_recipient_entries
      return if @message.message_recipients.present?

      recipient_numbers.find_in_batches do |batch|
        rows = batch.collect do |phone_nr|
          recipient_attrs(phone_nr, :pending)
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

    def recipient_attrs(phone_nr, state)
      { message_id: @message.id,
        created_at: @now,
        person_id: phone_nr.contactable_id,
        phone_number: phone_nr.number,
        state: state }
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

    def client
      @client ||= Messages::TextMessageProvider::Base.init(config: provider_config)
    end

    def not_ok?(status)
      !status[:status].eql?(:ok)
    end
  end
end
