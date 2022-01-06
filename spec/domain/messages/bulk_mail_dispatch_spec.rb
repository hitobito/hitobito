# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::BulkMailDispatch do
  let(:message) { messages(:mail) }
  let(:top_leader) { people(:top_leader) }
  let(:dispatch) { described_class.new(message, mail_factory) }
  let(:mail_factory) { double }

  let(:address_list) do
    [
      { person_id: top_leader.id, email: 'recipient1@example.com' },
      { person_id: top_leader.id, email: 'recipient2@example.com' }
    ]
  end

  before do
    allow(Truemail).to receive(:valid?).and_call_original
    Subscription.create!(mailing_list: mailing_lists(:leaders), subscriber: top_leader)
  end

  context '#run' do
    context 'without recipients' do
      it 'creates recipient entries with state pending' do
        expect(Messages::BulkMail::AddressList).to receive_message_chain(:new, :entries).and_return(address_list)

        expect do
          result = dispatch.run
          expect(result.needs_reenqueue?).to be_truthy
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
          result = dispatch.run
          expect(result.needs_reenqueue?).to be_falsey
        end.to change { MessageRecipient.count }.by(1)

        message.reload

        recipient1 = message.message_recipients.first
        expect(recipient1.state).to eq('failed')
        expect(recipient1.error).to eq('Invalid email')
        expect(recipient1.person_id).to eq(top_leader.id)
      end


    end

    context 'with recipients' do
      let(:successful_address) { 'success@example.com' }
      let(:failed_address) { 'fail@example.com' }
      let!(:successful_recipient) { MessageRecipient.new(message_id: message.id, person_id: top_leader.id, state: :pending, email: successful_address) }
      let!(:failed_recipient) { MessageRecipient.new(message_id: message.id, person_id: top_leader.id, state: :pending, email: failed_address) }

      before do
        message.update(message_recipients: [successful_recipient, failed_recipient])
      end

      def setup_delivery
        delivery = double
        expect(Messages::BulkMail::Delivery).to receive(:new)
          .with(
            mail_factory,
           [successful_address, failed_address],
            Messages::BulkMailDispatch::DELIVERY_RETRIES)
          .and_return(delivery)

        expect(delivery).to receive(:deliver)
        expect(delivery).to receive(:succeeded).and_return([successful_address])
        expect(delivery).to receive(:failed).and_return([failed_address])
      end

      it 'persists results' do
        setup_delivery

        result = dispatch.run
        expect(result.needs_reenqueue?).to be_falsey

        [successful_recipient, failed_recipient].each(&:reload)
        expect(successful_recipient.state).to eq("sent")
        expect(failed_recipient.state).to eq("failed")
      end

      it 'does not create any more recipient entries if already present' do
        setup_delivery

        expect do
          dispatch.run
        end.not_to change { MessageRecipient.count }
      end
    end
  end
end
