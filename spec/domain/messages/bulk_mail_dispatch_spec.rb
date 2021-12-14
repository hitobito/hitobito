# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::BulkMailDispatch do
  let(:message) { messages(:sms) }
  let(:top_leader) { people(:top_leader) }
  let!(:fixnet) { Fabricate(:phone_number, contactable: top_leader, label: 'Festnetz') }

  let(:dispatch) { described_class.new(message) }
  let(:client_double) { double(:client) }

  before do
    Subscription.create!(mailing_list: mailing_lists(:leaders), subscriber: top_leader)
    allow(dispatch).to receive(:client).and_return(client_double)
  end

  context '#run' do
    it 'sends mail to mailing list subscribers' do
      expect(client_double)
        .to receive(:send)
              .with(text: message.text, recipients: array_including(nr1regex, nr2regex))
              .and_return(status: :ok, message: 'OK')

      freeze_time do # avoid problems with scheduling the job
        delivery_report_double = double
        expect(Messages::TextMessageDeliveryReportJob)
          .to receive(:new).and_return(delivery_report_double)
        expect(delivery_report_double).to receive(:enqueue!)
                                            .with(run_at: 15.seconds.from_now)

        dispatch.run
      end

      expect(message.failed_count).to eq 0
      expect(message.state).to eq('finished')

      recipients = message.message_recipients
      expect(recipients.count).to eq(2)

      recipients.each do |r|
        nrs = [mobile1.number, mobile2.number]
        expect(nrs).to include(r.phone_number)
        expect(r.state).to eq('sent')
        expect(r.error).to be_blank
      end
    end
  end

  context '#init_recipient_entries' do
    it 'creates recipient entries with state pending' do
      expect do
        dispatch.send(:init_recipient_entries)
      end.to change { MessageRecipient.count }.by(2)

      recipient1 = message.message_recipients.first
      expect(recipient1.state).to eq('pending')
      expect(recipient1.person_id).to eq(top_leader.id)
      recipient2 = message.message_recipients.second
      expect(recipient2.state).to eq('pending')
      expect(recipient1.person_id).to eq(top_leader.id)
    end

    it 'does not create any more recipient entries if already present' do
      MessageRecipient.create!(message: message,
                               person: top_leader,
                               email: top_leader.email,
                               state: :pending)

      expect do
        dispatch.send(:init_recipient_entries)
      end.to change { MessageRecipient.count }.by(0)
    end
  end
end
