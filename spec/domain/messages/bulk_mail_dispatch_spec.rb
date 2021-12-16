# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::BulkMailDispatch do
  let(:message) { messages(:mail) }
  let(:top_leader) { people(:top_leader) }
  let(:dispatch) { described_class.new(message) }

  let(:address_list) {
    [
      { person_id: top_leader.id, email: 'recipient1@example.com' },
      { person_id: top_leader.id, email: 'recipient2@example.com' }
    ]
  }

  let(:recipients) {
    [
      MessageRecipient.new(message_id: message.id, person_id: top_leader.id, state: :pending, email: 'recipient1@example.com'),
      MessageRecipient.new(message_id: message.id, person_id: top_leader.id, state: :pending, email: 'recipient2@example.com')
    ]
  }

  before do
    allow(Truemail).to receive(:valid?).and_call_original
    Subscription.create!(mailing_list: mailing_lists(:leaders), subscriber: top_leader)
  end

  context '#run' do
    it 'delivers mail if message recipients do exist' do
      message.message_recipients = recipients

      expect(dispatch).to receive(:deliver_mails)

      dispatch.run
    end

    it 'creates message recipients if not existing' do
      expect(dispatch).to receive(:init_recipient_entries)

      dispatch.run
    end
  end

  context '#init_recipient_entries' do
    it 'creates recipient entries with state pending' do
      expect(Messages::BulkMail::AddressList).to receive_message_chain(:new, :entries).and_return(address_list)

      expect do
        dispatch.send(:init_recipient_entries)
      end.to change { MessageRecipient.count }.by(2)

      message.reload

      recipient1 = message.message_recipients.first
      expect(recipient1.state).to eq('pending')
      expect(recipient1.error).to eq(nil)
      expect(recipient1.person_id).to eq(top_leader.id)

      recipient2 = message.message_recipients.second
      expect(recipient2.state).to eq('pending')
      expect(recipient2.error).to eq(nil)
      expect(recipient2.person_id).to eq(top_leader.id)
    end

    it 'creates recipient with state failed when email invalid' do
      expect(Messages::BulkMail::AddressList).to receive_message_chain(:new, :entries).and_return([{ person_id: top_leader.id, email: 'invalid.com' }])

      expect do
        dispatch.send(:init_recipient_entries)
      end.to change { MessageRecipient.count }.by(1)

      message.reload

      recipient1 = message.message_recipients.first
      expect(recipient1.state).to eq('failed')
      expect(recipient1.error).to eq('Invalid email')
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
