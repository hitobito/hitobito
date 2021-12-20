# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::BulkMailDispatch do
  let(:message) { messages(:mail) }
  let(:dispatch) { described_class.new(message) }

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member)}

  before do
    allow(Truemail).to receive(:valid?).and_call_original
    Subscription.create!(mailing_list: mailing_lists(:leaders), subscriber: top_leader)
  end

  context '#run' do
    it 'delivers mail if message recipients do exist' do
      MessageRecipient.create!(message_id: message.id, person_id: top_leader.id, state: :pending, email: 'recipient1@example.com')
      MessageRecipient.create!(message_id: message.id, person_id: top_leader.id, state: :pending, email: 'recipient2@example.com')

      expect(dispatch).to receive(:deliver_mails)

      dispatch.run
    end

    it 'initializes message recipients on first run' do
      expect(dispatch).to receive(:init_recipient_entries)

      dispatch.run
    end
  end

  context '#init_recipient_entries' do
    it 'creates recipient entries with state pending' do
      top_leader.additional_emails << AdditionalEmail.new(label: 'second', email: 'second@example.com', mailings: true)

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
